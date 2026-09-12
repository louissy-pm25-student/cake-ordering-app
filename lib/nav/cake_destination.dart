enum CakeDestination {
  admin('Admin'),
  login('Log in'),
  register('Register'),
  verifyAccount('Verify account'),
  forgotPassword('Forgot password'),
  resetPassword('Reset password'),
  home('Home'),
  menu('Menu'),
  customize('Customize'),
  checkout('Checkout'),
  orders('Orders'),
  profile('Profile');

  final String label;
  const CakeDestination(this.label);
}
