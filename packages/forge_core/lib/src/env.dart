enum AppEnv {
  dev,
  prod;

  bool get isProd => this == AppEnv.prod;
}
