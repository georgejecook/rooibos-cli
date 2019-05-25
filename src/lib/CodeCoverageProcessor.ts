import * as brs from 'brs';
import * as Debug from 'debug';

import * as path from 'path';

import { CodeCoverageLineType } from './CodeCoverageType';
import File from './File';
import { ProcessorConfig } from './ProcessorConfig';

const debug = Debug('CodeCoverageProcessor');

export class CodeCoverageProcessor {

  constructor(config: ProcessorConfig) {
    this._config = config;
    this._fileId = 0;
    let fs = require('fs');
    this._filePathMap = new Map<number, string>();
    this._expectedCoverageMap = {};
    try {
      this._coverageBrsTemplate = fs.readFileSync(path.join(__dirname, './CodeCoverageTemplate.brs'), 'utf8');
      this._coverageComponentBrsTemplate = fs.readFileSync(path.join(__dirname, './CodeCoverage.brs'), 'utf8');
      this._coverageComponentXmlTemplate = fs.readFileSync(path.join(__dirname, './CodeCoverage.xml'), 'utf8');
    } catch (e) {
      console.log('Error:', e.stack);
    }
  }

  private _config: ProcessorConfig;
  private _fileId: number;
  private _coverageBrsTemplate: string;
  private _coverageComponentBrsTemplate: string;
  private _coverageComponentXmlTemplate: string;
  private _filePathMap: Map<number, string>;
  private _expectedCoverageMap: any;

  get config(): ProcessorConfig {
    return this._config;
  }

  public async process() {
    debug(`Running processor at path ${this.config.projectPath} `);

    const glob = require('glob-all');
    let processedFiles = [];
    let targetPath = path.resolve(this._config.projectPath);
    debug(`processing files at path ${targetPath} with pattern ${this._config.sourceFilePattern}`);
    let files = glob.sync(this._config.sourceFilePattern, {cwd: targetPath});
    for (const filePath of files) {
      const extension = path.extname(filePath).toLowerCase();
      if (extension === '.brs') {
        const projectPath = path.dirname(filePath);
        const fullPath = path.join(targetPath, projectPath);
        const filename = path.basename(filePath);

        const file = new File(fullPath, projectPath, filename, path.extname(filename));
        let lexResult = brs.lexer.Lexer.scan(file.getFileContents());
        let parser = new brs.parser.Parser();
        let parseResult = parser.parse(lexResult.tokens);
        file.ast = parseResult.statements;
        this.processFile(file);

        processedFiles.push(file);
      }
    }
    this.createCoverageComponent();
    debug(`finished processing code coverage`);
  }

  public processFile(file: File) {
    this._fileId++;
    let fileContents = '';
    let lines = file.getFileContents().split(/\r?\n/);
    let coverageMap: Map<number, number> = new Map<number, number>();
    let visitableLines = new Map<number, brs.parser.Stmt.Statement | OtherStatement>();
    this.getVisitibleLinesFor(file.ast, visitableLines);
    for (let lineNumber = 0; lineNumber < lines.length; lineNumber++) {
      let line = lines[lineNumber];
      let statement = visitableLines.get(lineNumber);
      let coverageType = CodeCoverageLineType.noCode;
      if (statement) {
        if (statement instanceof brs.parser.Stmt.If) {
          let conditionStartPos = statement.condition.location.start.column;
          let conditionEndPos = statement.condition.location.end.column;
          let funcCall = this.getFuncCallText(lineNumber, CodeCoverageLineType.condition);
          let conditionText = line.substr(conditionStartPos, conditionEndPos - conditionStartPos);
          let restofLineText = line.substring(conditionEndPos);
          line = `${line.substr(0, conditionStartPos)} ${funcCall} and (${conditionText}) ${restofLineText}`;
          coverageType = CodeCoverageLineType.condition;
        } else if (statement instanceof OtherStatement) {
          debug(`ignoring unsupported statments type`, statement);
          //is it an else if?
          //ignoring for now
          coverageType = CodeCoverageLineType.condition;
        } else {
          //all types that can be prefixed with the funcall and a colon (i.e for, while, return foreach, assign)
          let funcCall = this.getFuncCallText(lineNumber, CodeCoverageLineType.code);
          line = `${funcCall}: ${line}`;
          coverageType = CodeCoverageLineType.code;
        }
      } else {
        debug(`could not ascertain symbol type for line "${line} - ignoring`);
      }

      if (!line.endsWith('\n')) {
        line += '\n';
      }
      fileContents += line;
      if (coverageType !== CodeCoverageLineType.noCode) {
        coverageMap[lineNumber] = coverageType;
      }
    }
    this._expectedCoverageMap[this._fileId.toString().trim()] = coverageMap;
    this._filePathMap[this._fileId] = file.pkgUri;
    fileContents += this.getBrsAPIText(file, coverageMap);
    file.setFileContents(fileContents);
    debug(`Writing to ${file.fullPath}`);
    file.saveFileContents();
  }

  public getBrsAPIText(file: File, coverageMap: Map<number, number>): string {
    let lineMapText = this.getLineMapText(coverageMap);
    let template = this._coverageBrsTemplate.replace(/\#ID\#/g, this._fileId.toString().trim());
    return template;
  }

  public createCoverageComponent() {
    let targetPath = path.resolve(this._config.projectPath);
    let file = new File(path.resolve(path.join(targetPath), 'components'), 'components', 'CodeCoverage.xml', '.xml');
    file.setFileContents(this._coverageComponentXmlTemplate);
    debug(`Writing to ${file.fullPath}`);
    file.saveFileContents();

    file = new File(path.resolve(path.join(targetPath, 'components')), 'components', 'CodeCoverage.brs', '.brs');
    let template = this._coverageComponentBrsTemplate;
    template = template.replace(/\#EXPECTED_MAP\#/g, JSON.stringify(this._expectedCoverageMap));
    template = template.replace(/\#FILE_PATH_MAP\#/g, JSON.stringify(this._filePathMap));
    file.setFileContents(template);
    debug(`Writing to ${file.fullPath}`);
    file.saveFileContents();
  }

  public getLineMapText(lineMap: Map<number, number>): string {
    return JSON.stringify(lineMap);
    // let text = '[';
    // const limit = 200;
    // for (let i = 0; i < lineMap.length; i++) {
    //   text += lineMap[i].toString().trim() + ',';
    //   if (i > 0 && i % limit === 0) {
    //     text += '\n';
    //   }
    // }
    // text += ']';
    // return text;
  }

  private getFuncCallText(lineNumber: number, lineType: CodeCoverageLineType) {
    return `RBS_CC_${this._fileId}_reportLine(${lineNumber.toString().trim()}, ${lineType.toString().trim()})`;
  }

  private getVisitibleLinesFor(statements: ReadonlyArray<brs.parser.Stmt.Statement>, visitableLines: Map<number, brs.parser.Stmt.Statement | OtherStatement>) {
    for (let statement of statements) {
      if (statement instanceof brs.parser.Stmt.Function) {
        this.getVisitibleLinesFor(statement.func.body.statements, visitableLines);
      } else if (statement instanceof brs.parser.Stmt.If) {
        if (!visitableLines.has(statement.location.start.line - 1)) {
          visitableLines.set(statement.location.start.line - 1, statement);
        }
        if (statement.thenBranch) {
          this.getVisitibleLinesFor(statement.thenBranch.statements, visitableLines);
        }
        if (statement.elseIfs) {
          for (let i = 0; i < statement.elseIfs.length; i++) {
            let elseIfStatement = statement.elseIfs[i];
            this.getVisitibleLinesFor(elseIfStatement.thenBranch.statements, visitableLines);
            if (statement.tokens.elseIfs[i]) {
              let elseIfLine = statement.tokens.elseIfs[i].location.start.line - 1;
              if (!visitableLines.has(elseIfLine)) {
                visitableLines.set(elseIfLine, new OtherStatement(elseIfStatement));
              }
            }
          }
        }
        if (statement.elseBranch) {
          this.getVisitibleLinesFor(statement.elseBranch.statements, visitableLines);
        }
      } else if (statement instanceof brs.parser.Stmt.For
        || statement instanceof brs.parser.Stmt.ForEach
        || statement instanceof brs.parser.Stmt.While) {

        if (!visitableLines.has(statement.location.start.line - 1)) {
          visitableLines.set(statement.location.start.line - 1, statement);
        }
        this.getVisitibleLinesFor(statement.body.statements, visitableLines);
      } else if (statement instanceof brs.parser.Stmt.Expression
        || statement instanceof brs.parser.Stmt.Assignment
        || statement instanceof brs.parser.Stmt.DottedSet
        || statement instanceof brs.parser.Stmt.IndexedSet
        || statement instanceof brs.parser.Stmt.Print
        || statement instanceof brs.parser.Stmt.Return
      ) {
        if (!visitableLines.has(statement.location.start.line - 1)) {
          visitableLines.set(statement.location.start.line - 1, statement);
        }
      }
    }
  }
}

class OtherStatement {
  constructor(public statement: any) {

  }
}
