import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/expo.dart';
import '../../providers/buyer_provider.dart';
import '../../services/url_utils.dart';

class ExposVisitedView extends StatefulWidget {
  final BuyerProvider provider;

  const ExposVisitedView({super.key, required this.provider});

  @override
  State<ExposVisitedView> createState() => _ExposVisitedViewState();
}

class _ExposVisitedViewState extends State<ExposVisitedView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _contactSearchController = TextEditingController();
  String _contactSearchQuery = '';

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Copied $label to clipboard: $text')),
          ],
        ),
        backgroundColor: const Color(0xFF009647),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openWhatsApp(String phone) {
    final String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isNotEmpty) {
      final String waUrl = 'https://wa.me/$digitsOnly';
      UrlUtils.launchURL(waUrl);
    }
  }

  void _exportExposToCsv(BuildContext context, BuyerProvider p) {
    if (p.expos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expos available to export.')),
      );
      return;
    }

    final StringBuffer sb = StringBuffer();
    sb.writeln('"Expo Name","Venue","City/Place","Date","Country","Company Name","Contact Person","Position","Emails","Phone Numbers","Website","Address","City","Stall Location","Discussion Notes"');

    for (var expo in p.expos) {
      if (expo.contacts.isEmpty) {
        sb.writeln('"${_cleanCsv(expo.name)}","${_cleanCsv(expo.venue)}","${_cleanCsv(expo.place)}","${_cleanCsv(expo.expoDate)}","${_cleanCsv(expo.country)}","","","","","","","","","",""');
      } else {
        for (var c in expo.contacts) {
          sb.writeln('"${_cleanCsv(expo.name)}","${_cleanCsv(expo.venue)}","${_cleanCsv(expo.place)}","${_cleanCsv(expo.expoDate)}","${_cleanCsv(expo.country)}","${_cleanCsv(c.companyName)}","${_cleanCsv(c.personName)}","${_cleanCsv(c.personPosition)}","${_cleanCsv(c.emails.join(", "))}","${_cleanCsv(c.phoneNumbers.join(", "))}","${_cleanCsv(c.companyWebsite)}","${_cleanCsv(c.address)}","${_cleanCsv(c.city)}","${_cleanCsv(c.venueAddress)}","${_cleanCsv(c.companyDetails)}"');
        }
      }
    }

    final String csvText = sb.toString();
    final Uri dataUri = Uri.dataFromString(csvText, mimeType: 'text/csv', encoding: utf8);
    UrlUtils.launchURL(dataUri.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exported Expos & Met Companies to CSV / Excel!'),
        backgroundColor: Color(0xFF009647),
      ),
    );
  }

  String _cleanCsv(String text) {
    return text.replaceAll('"', '""').replaceAll('\n', ' ');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contactSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final selectedExpo = p.selectedExpo;

    if (selectedExpo != null) {
      return _buildExpoDetailView(context, p, selectedExpo);
    }

    return _buildExpoListView(context, p);
  }

  // ===========================================================================
  // 1. EXPOS LIST VIEW (Level 1)
  // ===========================================================================
  Widget _buildExpoListView(BuildContext context, BuyerProvider p) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final expos = p.expos.where((e) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return e.name.toLowerCase().contains(q) ||
          e.place.toLowerCase().contains(q) ||
          e.venue.toLowerCase().contains(q) ||
          e.country.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              const Icon(Icons.business_center_rounded, color: Color(0xFF8B2C69), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expos Visited',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Track all trade expos visited and business cards/contacts collected',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _exportExposToCsv(context, p),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: Text(isMobile ? 'Excel' : 'Export Excel/CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF009647),
                  side: const BorderSide(color: Color(0xFF009647)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddEditExpoDialog(context, p),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(isMobile ? 'Add' : 'Add Expo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2C69),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search expos by name, venue, city or country...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
        ),

        // Expo Cards List
        Expanded(
          child: expos.isEmpty
              ? _buildEmptyExposState(context, p)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: expos.length,
                  itemBuilder: (context, index) {
                    final expo = expos[index];
                    return _buildExpoCard(context, p, expo);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyExposState(BuildContext context, BuyerProvider p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B2C69).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_center_rounded,
                size: 48,
                color: Color(0xFF8B2C69),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No expos found matching "$_searchQuery"' : 'No Expos Visited Yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try clearing your search query'
                  : 'Click "Add Expo" to record trade expos you have visited (e.g. FI India 2016)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () => _showAddEditExpoDialog(context, p),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Your First Expo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2C69),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpoCard(BuildContext context, BuyerProvider p, ExpoItem expo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => p.selectExpo(expo),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B2C69).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_seat_rounded, color: Color(0xFF8B2C69), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expo.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (expo.venue.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_city_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(expo.venue, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                                ],
                              ),
                            if (expo.place.isNotEmpty || expo.country.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.place_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    [expo.place, expo.country].where((s) => s.isNotEmpty).join(', '),
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            if (expo.expoDate.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(expo.expoDate, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7), size: 20),
                        tooltip: 'Edit Expo',
                        onPressed: () => _showAddEditExpoDialog(context, p, expo: expo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        tooltip: 'Delete Expo',
                        onPressed: () => _confirmDeleteExpo(context, p, expo),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          '${expo.contacts.length} Companies / Contacts Met',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'Open Blank Directory Page',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8B2C69)),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF8B2C69)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. EXPO DETAIL VIEW / BLANK PAGE (Level 2)
  // ===========================================================================
  Widget _buildExpoDetailView(BuildContext context, BuyerProvider p, ExpoItem expo) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    final filteredContacts = expo.contacts.where((c) {
      if (_contactSearchQuery.isEmpty) return true;
      final q = _contactSearchQuery.toLowerCase();
      return c.companyName.toLowerCase().contains(q) ||
          c.personName.toLowerCase().contains(q) ||
          c.personPosition.toLowerCase().contains(q) ||
          c.companyDetails.toLowerCase().contains(q) ||
          c.companyWebsite.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q) ||
          c.country.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q) ||
          c.venueAddress.toLowerCase().contains(q) ||
          c.emails.any((e) => e.toLowerCase().contains(q)) ||
          c.phoneNumbers.any((ph) => ph.toLowerCase().contains(q));
    }).toList();

    return Column(
      children: [
        // Detail Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _contactSearchController.clear();
                      _contactSearchQuery = '';
                      p.selectExpo(null);
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back to Expos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      expo.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditContactDialog(context, p, expo.id),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(isMobile ? 'Add' : 'Add Company Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B2C69),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (expo.venue.isNotEmpty)
                    Text('Venue: ${expo.venue}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  if (expo.place.isNotEmpty || expo.country.isNotEmpty)
                    Text(
                      'Location: ${[expo.place, expo.country].where((s) => s.isNotEmpty).join(", ")}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  if (expo.expoDate.isNotEmpty)
                    Text('Date: ${expo.expoDate}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ),

        // Contact Search Bar inside Expo Details Page
        if (expo.contacts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _contactSearchController,
              onChanged: (val) => setState(() => _contactSearchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search company, contact person, email, phone, city, country or notes in ${expo.name}...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                suffixIcon: _contactSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _contactSearchController.clear();
                          setState(() => _contactSearchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ),

        // Detail Content: Contact Cards List or Blank Canvas State
        Expanded(
          child: expo.contacts.isEmpty
              ? _buildBlankExpoPage(context, p, expo)
              : filteredContacts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              'No contacts found matching "$_contactSearchQuery"',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                _contactSearchController.clear();
                                setState(() => _contactSearchQuery = '');
                              },
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              label: const Text('Clear Search'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        return _buildContactCard(context, p, expo.id, contact);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildBlankExpoPage(BuildContext context, BuyerProvider p, ExpoItem expo) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.contact_mail_outlined,
                size: 44,
                color: Color(0xFF8B2C69),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Blank Directory Page for ${expo.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const Text(
                'No company or business card details added yet. Click "+ Add Company Details" to enter details of companies & representatives you met at this expo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddEditContactDialog(context, p, expo.id),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Company Details Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2C69),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, BuyerProvider p, String expoId, ExpoContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Company Name & Person Name + Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business_rounded, color: Color(0xFF0284C7), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.companyName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (contact.personName.isNotEmpty || contact.personPosition.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            [
                              if (contact.personName.isNotEmpty) 'Contact: ${contact.personName}',
                              if (contact.personPosition.isNotEmpty) '(${contact.personPosition})',
                            ].join(' '),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7), size: 20),
                      tooltip: 'Edit Contact Details',
                      onPressed: () => _showAddEditContactDialog(context, p, expoId, contact: contact),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      tooltip: 'Delete Contact Details',
                      onPressed: () => _confirmDeleteContact(context, p, expoId, contact),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Contact Info Details (Emails, Phones with Copy & WhatsApp, Website, Location)
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                if (contact.emails.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: 15, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text('Emails:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: contact.emails.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Send Email',
                                  child: InkWell(
                                    onTap: () => UrlUtils.launchEmail(e),
                                    child: Text(
                                      e,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0284C7),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: 'Copy Email',
                                  child: InkWell(
                                    onTap: () => _copyToClipboard(context, e, 'email address'),
                                    child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                if (contact.phoneNumbers.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, size: 15, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text('Phone Numbers:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: contact.phoneNumbers.map((ph) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ph,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Copy Button
                                Tooltip(
                                  message: 'Copy Phone Number',
                                  child: InkWell(
                                    onTap: () => _copyToClipboard(context, ph, 'phone number'),
                                    child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0284C7)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // WhatsApp Button
                                Tooltip(
                                  message: 'Check & Chat on WhatsApp',
                                  child: InkWell(
                                    onTap: () => _openWhatsApp(ph),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.chat_rounded, size: 11, color: Colors.white),
                                          SizedBox(width: 3),
                                          Text(
                                            'WhatsApp',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                if (contact.companyWebsite.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language_rounded, size: 15, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text('Website:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Tooltip(
                        message: 'Open Website in browser',
                        child: InkWell(
                          onTap: () => UrlUtils.launchURL(contact.companyWebsite),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  contact.companyWebsite,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF0284C7)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (contact.city.isNotEmpty || contact.country.isNotEmpty || contact.address.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        [contact.address, contact.city, contact.country].where((s) => s.isNotEmpty).join(', '),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                if (contact.venueAddress.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'Booth/Stall: ${contact.venueAddress}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
              ],
            ),

            if (contact.companyDetails.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Notes / Met Discussion:\n${contact.companyDetails}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. DIALOGS & ACTION HANDLERS
  // ===========================================================================

  void _showAddEditExpoDialog(BuildContext context, BuyerProvider p, {ExpoItem? expo}) {
    final isEdit = expo != null;
    final nameCtrl = TextEditingController(text: expo?.name ?? '');
    final placeCtrl = TextEditingController(text: expo?.place ?? '');
    final venueCtrl = TextEditingController(text: expo?.venue ?? '');
    final dateCtrl = TextEditingController(text: expo?.expoDate ?? '');
    final countryCtrl = TextEditingController(text: expo?.country ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit_outlined : Icons.add_rounded, color: const Color(0xFF8B2C69)),
            const SizedBox(width: 8),
            Text(isEdit ? 'Edit Expo' : 'Add Visited Expo'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expo Name *',
                  hintText: 'e.g. FI India 2016',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: venueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expo Venue',
                  hintText: 'e.g. Pragati Maidan / BKC',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expo Date',
                  hintText: 'e.g. 14-16 Oct 2016',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: placeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City / Place',
                        hintText: 'e.g. Mumbai',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: countryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        hintText: 'e.g. India',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B2C69), foregroundColor: Colors.white),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              if (isEdit) {
                p.editExpo(expo.copyWith(
                  name: name,
                  place: placeCtrl.text.trim(),
                  venue: venueCtrl.text.trim(),
                  expoDate: dateCtrl.text.trim(),
                  country: countryCtrl.text.trim(),
                ));
              } else {
                p.addExpo(ExpoItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  place: placeCtrl.text.trim(),
                  venue: venueCtrl.text.trim(),
                  expoDate: dateCtrl.text.trim(),
                  country: countryCtrl.text.trim(),
                ));
              }
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save Changes' : 'Add Expo'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpo(BuildContext context, BuyerProvider p, ExpoItem expo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expo?'),
        content: Text('Are you sure you want to delete "${expo.name}" and all its saved company contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              p.deleteExpo(expo.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEditContactDialog(BuildContext context, BuyerProvider p, String expoId, {ExpoContact? contact}) {
    final isEdit = contact != null;
    final companyCtrl = TextEditingController(text: contact?.companyName ?? '');
    final detailsCtrl = TextEditingController(text: contact?.companyDetails ?? '');
    final personCtrl = TextEditingController(text: contact?.personName ?? '');
    final posCtrl = TextEditingController(text: contact?.personPosition ?? '');
    final websiteCtrl = TextEditingController(text: contact?.companyWebsite ?? '');
    final addrCtrl = TextEditingController(text: contact?.address ?? '');
    final cityCtrl = TextEditingController(text: contact?.city ?? '');
    final countryCtrl = TextEditingController(text: contact?.country ?? '');
    final venueAddrCtrl = TextEditingController(text: contact?.venueAddress ?? '');

    final List<TextEditingController> emailCtrls = contact != null && contact.emails.isNotEmpty
        ? contact.emails.map((e) => TextEditingController(text: e)).toList()
        : [TextEditingController()];

    final List<TextEditingController> phoneCtrls = contact != null && contact.phoneNumbers.isNotEmpty
        ? contact.phoneNumbers.map((ph) => TextEditingController(text: ph)).toList()
        : [TextEditingController()];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(isEdit ? Icons.edit_outlined : Icons.person_add_rounded, color: const Color(0xFF8B2C69)),
                  const SizedBox(width: 8),
                  Text(isEdit ? 'Edit Met Company Details' : 'Add Met Company Details'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: companyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Company Name *',
                          hintText: 'e.g. ABC Foods Trading Co.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: personCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Person Name Met',
                                hintText: 'e.g. John Doe',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: posCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Position / Designation',
                                hintText: 'e.g. Purchase Manager',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // DYNAMIC MULTIPLE EMAILS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Email Addresses (Multiple)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                emailCtrls.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add Email', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      ...emailCtrls.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final ctrl = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: ctrl,
                                  decoration: InputDecoration(
                                    labelText: 'Email ${idx + 1}',
                                    hintText: 'e.g. contact@company.com',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (emailCtrls.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      emailCtrls.removeAt(idx);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      // DYNAMIC MULTIPLE PHONES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Phone Numbers (Multiple)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                phoneCtrls.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add Phone', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      ...phoneCtrls.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final ctrl = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: ctrl,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number ${idx + 1}',
                                    hintText: 'e.g. +91 9876543210',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (phoneCtrls.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      phoneCtrls.removeAt(idx);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      TextField(
                        controller: websiteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Company Website',
                          hintText: 'e.g. www.abcfoods.com',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addrCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          hintText: 'e.g. Street / Business Park',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cityCtrl,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                hintText: 'e.g. Dubai',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: countryCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Country',
                                hintText: 'e.g. UAE',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: venueAddrCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Stall / Booth Location at Venue',
                          hintText: 'e.g. Hall 3, Stall B-12',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: detailsCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Company Details / Discussion Notes',
                          hintText: 'Met at booth, exchanged cards, interested in fruit products...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B2C69), foregroundColor: Colors.white),
                  onPressed: () {
                    final companyName = companyCtrl.text.trim();
                    if (companyName.isEmpty) return;

                    final validEmails = emailCtrls.map((c) => c.text.trim()).where((e) => e.isNotEmpty).toList();
                    final validPhones = phoneCtrls.map((c) => c.text.trim()).where((ph) => ph.isNotEmpty).toList();

                    final newContact = ExpoContact(
                      id: isEdit ? contact.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      companyName: companyName,
                      companyDetails: detailsCtrl.text.trim(),
                      emails: validEmails,
                      phoneNumbers: validPhones,
                      companyWebsite: websiteCtrl.text.trim(),
                      personName: personCtrl.text.trim(),
                      personPosition: posCtrl.text.trim(),
                      address: addrCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      country: countryCtrl.text.trim(),
                      venueAddress: venueAddrCtrl.text.trim(),
                    );

                    if (isEdit) {
                      p.editExpoContact(expoId, newContact);
                    } else {
                      p.addContactToExpo(expoId, newContact);
                    }

                    Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Save Details' : 'Add Contact'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteContact(BuildContext context, BuyerProvider p, String expoId, ExpoContact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact Details?'),
        content: Text('Are you sure you want to delete contact details for "${contact.companyName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              p.deleteExpoContact(expoId, contact.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
