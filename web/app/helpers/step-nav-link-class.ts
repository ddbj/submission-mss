import { helper } from '@ember/component/helper';

interface StepNav {
  currentStep: string;
  isFollowing(step: string): boolean;
}

export default helper(function stepNavLinkClass([nav, step]: [StepNav, string]) {
  return step === nav.currentStep
    ? 'active'
    : nav.currentStep === 'complete'
      ? 'disabled'
      : nav.isFollowing(step)
        ? 'disabled'
        : null;
});
