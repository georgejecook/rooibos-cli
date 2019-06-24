import File from './File';
import { ItGroup } from './ItGroup';

export class TestSuite {

  constructor() {
    this.name = '';
    this.isValid = false;
    this.hasFailures = false;
    this.hasSoloTests = false;
    this.hasIgnoredTests = false;
    this.hasSoloGroups = false;
    this.isSolo = false;
    this.isIgnored = false;
    this.itGroups = [];
    this.setupFunctionName = '';
    this.tearDownFunctionName = '';
    this.isNodeTest = false;
    this.nodeTestFileName = '';
    this.isLegacy = false;
  }

  public filePath: string;
  public name: string;
  public isNodeTest: boolean;
  public isSolo: boolean;
  public isIgnored: boolean;
  public isValid: boolean;
  public isIncluded: boolean;

  public itGroups: ItGroup[];
  public hasFailures: boolean;
  public hasSoloTests: boolean;
  public hasIgnoredTests: boolean;
  public hasSoloGroups: boolean;
  public setupFunctionName: string;
  public tearDownFunctionName: string;
  public beforeEachFunctionName: string;
  public nodeTestFileName: string;
  public afterEachFunctionName: string;
  public rawParams: string;
  public isLegacy: boolean;

  public asJson(): object {
    return {
      name: this.name,
      filePath: this.filePath,
      valid: this.isValid,
      hasFailures: this.hasFailures,
      hasSoloTests: this.hasSoloTests,
      hasIgnoredTests: this.hasIgnoredTests,
      hasSoloGroups: this.hasSoloGroups,
      isSolo: this.isSolo,
      isIgnored: this.isIgnored,
      itGroups: this.itGroups.filter( (itGroup) => itGroup.isIncluded)
        .map((itGroup) => itGroup.asJson()),
      setupFunctionName: this.setupFunctionName,
      tearDownFunctionName: this.tearDownFunctionName,
      isNodeTest: this.isNodeTest,
      nodeTestFileName: this.nodeTestFileName,
      beforeEachFunctionName: this.beforeEachFunctionName,
      afterEachFunctionName: this.afterEachFunctionName,
    };
  }

  public asText(): string {
    let itGroups = this.itGroups.filter( (itGroup) => itGroup.isIncluded)
      .map((itGroup) => itGroup.asText());
    return `{
      name: "${this.name}"
      filePath: "${this.filePath}"
      valid: ${this.isValid}
      hasFailures: ${this.hasFailures}
      hasSoloTests: ${this.hasSoloTests}
      hasIgnoredTests: ${this.hasIgnoredTests}
      hasSoloGroups: ${this.hasSoloGroups}
      isSolo: ${this.isSolo}
      isIgnored: ${this.isIgnored}
      itGroups: [${itGroups}]
      setupFunctionName: "${this.setupFunctionName || ''}"
      tearDownFunctionName: "${this.tearDownFunctionName || ''}"
      isNodeTest: ${this.isNodeTest}
      isLegacy: ${this.isLegacy}
      nodeTestFileName: "${this.nodeTestFileName || ''}"
      beforeEachFunctionName: "${this.beforeEachFunctionName || ''}"
      afterEachFunctionName: "${this.afterEachFunctionName || ''}"
    }`;
  }
}
