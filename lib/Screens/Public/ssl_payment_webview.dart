import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef PaymentResultCallback = void Function(PaymentResult result);

class PaymentResult {
  final bool success;
  final String? message;
  final Map<String, String>? params;
  PaymentResult({required this.success, this.message, this.params});
}

class SSLPaymentWebViewscreen extends StatefulWidget {
  final String paymentUrl;
  final String title;
  final PaymentResultCallback? onResult;
  final Uri? successRedirectUri; // optional known success redirect
  final Uri? failRedirectUri; // optional known failure redirect

  const SSLPaymentWebViewscreen({
    Key? key,
    required this.paymentUrl,
    required this.title,
    this.onResult,
    this.successRedirectUri,
    this.failRedirectUri,
  }) : super(key: key);

  @override
  State<SSLPaymentWebViewscreen> createState() => _SSLPaymentWebViewState();
}

class _SSLPaymentWebViewState extends State<SSLPaymentWebViewscreen> {
  bool _isLoading = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest req) {
            final uri = Uri.tryParse(req.url);
            if (uri != null) {
              // If backend redirects to known success or fail URL, detect & close
              if (widget.successRedirectUri != null &&
                  _isSameBase(uri, widget.successRedirectUri!)) {
                widget.onResult?.call(PaymentResult(success: true, params: uri.queryParameters));
                Navigator.of(context).pop();
                return NavigationDecision.prevent;
              }
              if (widget.failRedirectUri != null &&
                  _isSameBase(uri, widget.failRedirectUri!)) {
                widget.onResult?.call(PaymentResult(success: false, params: uri.queryParameters));
                Navigator.of(context).pop();
                return NavigationDecision.prevent;
              }

              // Optional: heuristics if you know the provider includes "success" or "failed" in URL
              if (req.url.contains('success') || req.url.contains('status=success')) {
                widget.onResult?.call(PaymentResult(success: true, params: uri.queryParameters));
                Navigator.of(context).pop();
                return NavigationDecision.prevent;
              }
              if (req.url.contains('fail') || req.url.contains('status=failed')) {
                widget.onResult?.call(PaymentResult(success: false, params: uri.queryParameters));
                Navigator.of(context).pop();
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) => setState(() => _isLoading = true),
          onPageFinished: (String url) => setState(() => _isLoading = false),
          onWebResourceError: (err) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isSameBase(Uri a, Uri b) {
    return a.scheme == b.scheme && a.host == b.host && a.path == b.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
