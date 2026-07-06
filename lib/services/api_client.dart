import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:real_estate_crm_sales/config/app_config.dart';
import 'package:real_estate_crm_sales/models/commission_summary.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/models/follow_up.dart';
import 'package:real_estate_crm_sales/models/invoice.dart';
import 'package:real_estate_crm_sales/models/lead.dart';
import 'package:real_estate_crm_sales/models/payment.dart';

class ApiClient {
  String token = '';

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    _throwIfFailed(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    token = data['token'] as String;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/me'),
      headers: headers,
    );
    _throwIfFailed(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Lead>> getLeads() async {
    final data = await _getList('/leads');
    return data.map((item) => Lead.fromJson(item)).toList();
  }

  Future<List<FollowUp>> getFollowUps() async {
    final data = await _getList('/followups');
    return data.map((item) => FollowUp.fromJson(item)).toList();
  }

  Future<List<Customer>> getCustomers() async {
    final data = await _getList('/customers');
    return data.map((item) => Customer.fromJson(item)).toList();
  }

  Future<List<Invoice>> getInvoices() async {
    final data = await _getList('/invoices');
    return data.map((item) => Invoice.fromJson(item)).toList();
  }

  Future<List<Payment>> getPayments() async {
    final data = await _getList('/payments');
    return data.map((item) => Payment.fromJson(item)).toList();
  }

  Future<CommissionSummary> getCommission() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/commissions/me'),
      headers: headers,
    );

    _throwIfFailed(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CommissionSummary.fromJson(data);
  }

  Future<String> uploadFile(String path, {String category = 'proofs'}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/files/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['category'] = category;
    request.files.add(await http.MultipartFile.fromPath('file', path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _throwIfFailed(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<void> submitFollowUp({
    required int leadId,
    required int type,
    required String summary,
    required String customerResponse,
    DateTime? nextFollowUpAt,
    int? newLeadStatus,
    String? proofUrl,
    int? proofType,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/followups'),
      headers: headers,
      body: jsonEncode({
        'leadId': leadId,
        'customerId': null,
        'type': type,
        'summary': summary,
        'customerResponse': customerResponse,
        'nextFollowUpAt':
            (nextFollowUpAt ?? DateTime.now().add(const Duration(days: 1)))
                .toUtc()
                .toIso8601String(),
        'newLeadStatus': newLeadStatus,
        'proofs': proofUrl == null || proofUrl.isEmpty
            ? []
            : [
                {'proofType': proofType ?? 4, 'fileUrl': proofUrl}
              ],
      }),
    );

    _throwIfFailed(response);
  }

  Future<void> createInvoice({
    required int customerId,
    required double amount,
    required DateTime dueDate,
    double discount = 0,
    double tax = 0,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/invoices'),
      headers: headers,
      body: jsonEncode({
        'customerId': customerId,
        'projectId': null,
        'unitId': null,
        'salesExecutiveId': null,
        'dueDate': dueDate.toUtc().toIso8601String(),
        'amount': amount,
        'discount': discount,
        'tax': tax,
      }),
    );

    _throwIfFailed(response);
  }

  Future<void> submitPayment(
    int invoiceId,
    double amount,
    String proofUrl,
  ) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/payments/manual'),
      headers: headers,
      body: jsonEncode({
        'invoiceId': invoiceId,
        'amount': amount,
        'method': 0,
        'proofUrl': proofUrl,
        'remarks': 'Submitted from sales app',
      }),
    );

    _throwIfFailed(response);
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: headers,
    );

    _throwIfFailed(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 400) {
      String message = response.body;
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        message = data['message']?.toString() ?? response.body;
      } catch (_) {
        message = response.body;
      }
      throw Exception(message);
    }
  }
}

final apiClient = ApiClient();
