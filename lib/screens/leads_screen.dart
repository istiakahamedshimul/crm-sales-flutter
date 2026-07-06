import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:real_estate_crm_sales/models/lead.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/widgets/empty_state.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  late Future<List<Lead>> leads = apiClient.getLeads();

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Assigned Leads',
      subtitle: 'ADMIN ASSIGNED',
      action: IconButton.filledTonal(
        onPressed: () => setState(() => leads = apiClient.getLeads()),
        icon: const Icon(Icons.refresh),
      ),
      child: FutureBuilder<List<Lead>>(
        future: leads,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                heightFactor: 8, child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const EmptyState(
                text:
                    'No leads assigned yet. Admin will assign leads to your account.');
          }

          return Column(
            children: [
              SalesCard(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xff0f766e)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sales executives can follow up on assigned leads. Lead creation is controlled by admin.',
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final lead in data) ...[
                _LeadCard(lead: lead, onFollowUp: () => openFollowUp(lead)),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> openFollowUp(Lead lead) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FollowUpSheet(lead: lead),
    );

    if (saved == true) {
      setState(() => leads = apiClient.getLeads());
    }
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead, required this.onFollowUp});

  final Lead lead;
  final VoidCallback onFollowUp;

  @override
  Widget build(BuildContext context) {
    return SalesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lead.customerName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              StatusPill(label: enumLabel(leadPriorities, lead.priority)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                  label: enumLabel(leadStatuses, lead.status),
                  color: const Color(0xff2563eb)),
              StatusPill(label: lead.phone, color: const Color(0xff667085)),
              if (lead.nextFollowUpAt != null)
                StatusPill(
                    label: shortDate(lead.nextFollowUpAt),
                    color: const Color(0xffb54708)),
            ],
          ),
          if (lead.email != null && lead.email!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(lead.email!, style: const TextStyle(color: Color(0xff667085))),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onFollowUp,
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Follow-up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowUpSheet extends StatefulWidget {
  const _FollowUpSheet({required this.lead});

  final Lead lead;

  @override
  State<_FollowUpSheet> createState() => _FollowUpSheetState();
}

class _FollowUpSheetState extends State<_FollowUpSheet> {
  final summary = TextEditingController();
  final response = TextEditingController();
  final proof = TextEditingController();
  String? selectedFilePath;
  int type = 0;
  int nextStatus = 4;
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    summary.dispose();
    response.dispose();
    proof.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Follow-up: ${widget.lead.customerName}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: type,
            decoration: const InputDecoration(labelText: 'Follow-up type'),
            items: [
              for (var i = 0; i < followUpTypes.length; i++)
                DropdownMenuItem(value: i, child: Text(followUpTypes[i])),
            ],
            onChanged: (value) => setState(() => type = value ?? 0),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: summary,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Summary')),
          const SizedBox(height: 12),
          TextField(
              controller: response,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Customer response')),
          const SizedBox(height: 12),
          TextField(
              controller: proof,
              decoration:
                  const InputDecoration(labelText: 'Proof URL / uploaded URL')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: pickProof,
            icon: const Icon(Icons.attach_file),
            label: Text(selectedFilePath == null
                ? 'Choose proof file'
                : selectedFilePath!.split(RegExp(r'[\\/]')).last),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: nextStatus,
            decoration: const InputDecoration(labelText: 'Update lead status'),
            items: [
              for (var i = 0; i < leadStatuses.length; i++)
                DropdownMenuItem(value: i, child: Text(leadStatuses[i])),
            ],
            onChanged: (value) => setState(() => nextStatus = value ?? 4),
          ),
          if (error.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(error,
                    style: const TextStyle(color: Color(0xffb42318)))),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : submit,
            child: Text(loading ? 'Submitting...' : 'Submit Follow-up'),
          ),
        ],
      ),
    );
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      var proofUrl = proof.text.trim();
      if (selectedFilePath != null) {
        proofUrl = await apiClient.uploadFile(
          selectedFilePath!,
          category: 'followups',
        );
      }

      await apiClient.submitFollowUp(
        leadId: widget.lead.id,
        type: type,
        summary: summary.text,
        customerResponse: response.text,
        newLeadStatus: nextStatus,
        proofUrl: proofUrl,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp3', 'm4a', 'wav'],
    );

    final path = result?.files.single.path;
    if (path != null) {
      setState(() => selectedFilePath = path);
    }
  }
}
