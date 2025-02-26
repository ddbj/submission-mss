import { helper } from '@ember/component/helper';

export default helper(function stepNavLinkClass([nav, step]) {
  return step === nav.currentStep
    ? 'active'
    : nav.currentStep === 'complete'
      ? 'disabled'
      : nav.isFollowing(step)
        ? 'disabled'
        : null;
});
