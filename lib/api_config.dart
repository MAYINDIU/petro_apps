// Central API configuration. Change [ApiConfig.baseUrl] to point the whole app
// at a different server.
class ApiConfig {
  static const String baseUrl =
      "https://wmsmarketcompany.com/cashless-fuel-api/public";

  static const String apiUrl = "$baseUrl/api/v1";
  static const String storageUrl = "$baseUrl/storage/";

  // Auth
  static const String login = "$apiUrl/auth/login";
  static const String register = "$apiUrl/auth/register";
  static const String logout = "$apiUrl/auth/logout";

  // Driver
  static const String driverMe = "$apiUrl/driver/me";
  static const String driverQr = "$apiUrl/driver/qr";
  static const String driverTransactions = "$apiUrl/driver/transactions";
  static const String driverWallet = "$apiUrl/driver/wallet";

  // Station
  static const String stationScan = "$apiUrl/station/scan";
  static const String stationFuelPurchase = "$apiUrl/station/fuel-purchase";
}
