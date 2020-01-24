import File from './File';
import { FileFeedback, FileFeedbackType } from './FileFeedback';

const _feedback: FileFeedback[] = [];

export function feedbackMessage(type: FileFeedbackType, file: File | null, message: string, isThrown: boolean = false) {
  let error = new FileFeedback(file, type, message);
  _feedback.push(error);
  if (isThrown) {
    error.throw();
  }
}

export function resetFeedback() {
  _feedback.splice(0, _feedback.length);
}

export function feedbackInfo(file: File, message: string, isThrown: boolean = false) {
  feedbackMessage(FileFeedbackType.Info, file, message, isThrown);
}
export function feedbackWarning(file: File, message: string, isThrown: boolean = false) {
  feedbackMessage(FileFeedbackType.Warning, file, message, isThrown);
}
export function feedbackError(file: File, message: string, isThrown: boolean = false) {
  feedbackMessage(FileFeedbackType.Error, file, message, isThrown);
}

export function getFeedbackErrors(): FileFeedback[] {
  return _feedback.filter((feedback) => feedback.feedbackType === FileFeedbackType.Error);
}

export function getFeedbackWarnings(): FileFeedback[] {
  return _feedback.filter((feedback) => feedback.feedbackType === FileFeedbackType.Warning);
}

export function getFeedbackInfos(): FileFeedback[] {
  return _feedback.filter((feedback) => feedback.feedbackType === FileFeedbackType.Info);
}
