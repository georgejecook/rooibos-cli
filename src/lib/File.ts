import * as brs from 'brs';
import * as fs from 'fs';
import * as path from 'path';

import { Statement } from 'brs/types/parser/Statement';

import { FileType } from './FileType';

/**
 * describes a file in our project.
 */
export default class File {

  constructor(fsPath: string, projectPath: string, filename: string, extension: string) {
    this.filename = filename;
    this._fsPath = fsPath;
    this._fullPath = path.join(fsPath, filename);
    this._pkgPath = path.join(projectPath, filename);
    this._pkgUri = `pkg:/${path.join(projectPath, filename)}`;
    this.projectPath = projectPath;
    this.extension = extension;
    this._importedNamespaceNames = new Set();
    this.componentIds = new Set<string>();
    this.associatedFile = null;
    this.parentFile = null;
    this._fileContents = null;
    this.hasProcessedImports = false;
  }

  private _fsPath: string;
  private _pkgPath: string;
  private _pkgUri: string;
  private _fullPath: string;
  public hasProcessedImports: boolean;
  public filename: string;
  public projectPath: string;
  public extension: string;
  public associatedFile?: File;
  public parentFile?: File;
  public ast: Statement[];
  public componentIds: Set<string>;

  private readonly _importedNamespaceNames: Set<string>;

  private _fileContents: string;

  get fileType(): FileType {
    switch (this.extension.toLowerCase()) {
      case '.brs':
        return this.associatedFile ? FileType.CodeBehind : FileType.Brs;
      case '.bs':
        return this.associatedFile ? FileType.CodeBehind : FileType.Bs;
      case '.xml':
        return this.associatedFile ? FileType.ViewXml : FileType.Xml;
      default:
        return FileType.Other;
    }
  }

  public get fsPath() {
    return this._fsPath;
  }

  public get importedNamespaceNames(): Set<string> {
    return this._importedNamespaceNames;
  }
  public get fullPath() {
    return this._fullPath;
  }

  public get pkgPath() {
    return this._pkgPath;
  }

  public get pkgUri() {
    return this._pkgUri;
  }

  public get normalizedFileName() {
    return this.filename.replace('.brs', '').replace('-', '_').replace('.', '_');
  }

  public get normalizedFullFileName() {
    return this.fullPath.replace('/', '_') + this.normalizedFileName;
  }

  public getFileContents(): string {
    if (this._fileContents === null) {
      this._fileContents = fs.readFileSync(this.fullPath, 'utf8');
    }
    return this._fileContents;
  }

  public setFileContents(fileContents: string) {
    this._fileContents = fileContents;
  }

  public saveFileContents() {
    fs.writeFileSync(this.fullPath, this._fileContents, 'utf8');
  }

  public unloadContents() {
    this._fileContents = null;
  }

  public toString(): string {
    return `DESCRIPTOR: ${this.filename} TYPE ${this.fileType} PATH ${this.fullPath}`;
  }

}
