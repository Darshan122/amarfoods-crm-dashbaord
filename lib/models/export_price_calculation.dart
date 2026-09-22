import 'package:intl/intl.dart';

/// Itemized Port Logistics charge item from official Quotation (14-08-2026)
class PortLogisticsItem {
  final String name;
  final double amount40Hc;
  final double amount20Gp;
  final String unit;
  final String note;

  const PortLogisticsItem({
    required this.name,
    required this.amount40Hc,
    required this.amount20Gp,
    required this.unit,
    required this.note,
  });
}

/// Destination port preset with reference sea freight rates
class PortPreset {
  final String portName;
  final String country;
  final double freight40HcUsd;
  final double freight20GpUsd;
  final String transitDays;

  const PortPreset({
    required this.portName,
    required this.country,
    required this.freight40HcUsd,
    required this.freight20GpUsd,
    required this.transitDays,
  });

  String get displayName => '$portName ($country)';
}

/// FOB, CFR & CIF Export Price Calculator Engine
class ExportPriceCalculation {
  // Official Pipavav Port Logistics breakdown items (Quotation dated 14-08-2026)
  static const List<PortLogisticsItem> officialLogisticsItems = [
    PortLogisticsItem(
      name: 'Transportation (Pipavav - Bhadara - Pipavav)',
      amount40Hc: 18290.00,
      amount20Gp: 14160.00,
      unit: '₹ / Cont.',
      note: 'Round-trip factory to port trailer (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'Terminal Handling Charges (THC)',
      amount40Hc: 21476.00,
      amount20Gp: 13570.00,
      unit: '₹ / Cont.',
      note: 'Pipavav Port terminal loading & handling (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'CFS Handling & Stuffing Charges',
      amount40Hc: 15340.00,
      amount20Gp: 12980.00,
      unit: '₹ / Cont.',
      note: 'Container Freight Station stuffing & labor (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'Buffer Yard Charges',
      amount40Hc: 6490.00,
      amount20Gp: 6490.00,
      unit: '₹ / Cont.',
      note: 'Container buffer yard storage & inspection (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'BL & Export Documentation Charges',
      amount40Hc: 6018.00,
      amount20Gp: 6018.00,
      unit: '₹ / Cont.',
      note: 'Bill of Lading + EDI Customs Filing (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'Plant Quarantine (Phyto) Certificate',
      amount40Hc: 3304.00,
      amount20Gp: 3304.00,
      unit: '₹ / Cont.',
      note: 'Govt. Phytosanitary inspection & clearance (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'Fumigation Charges (Phosphine/MBr)',
      amount40Hc: 3776.00,
      amount20Gp: 3776.00,
      unit: '₹ / Cont.',
      note: 'Certified food-grade container fumigation (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'Agency & Forwarder Handling',
      amount40Hc: 3304.00,
      amount20Gp: 3304.00,
      unit: '₹ / Cont.',
      note: 'Customs clearance & forwarder coordination (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'Container Lift On / Lift Off (Yard Pickup)',
      amount40Hc: 0.00,
      amount20Gp: 2242.00,
      unit: '₹ / Cont.',
      note: 'Yard pickup (40\' HC: ₹0 at terminal | 20\' GP: ₹2,242.00 incl. GST)',
    ),
    PortLogisticsItem(
      name: 'Seal + MUC + EDI + VGM Charges',
      amount40Hc: 1621.40,
      amount20Gp: 1621.40,
      unit: '₹ / Cont.',
      note: 'Verified Gross Mass + Bolt Seal + Port EDI (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'Cargo Unloading Charges',
      amount40Hc: 1274.40,
      amount20Gp: 708.00,
      unit: '₹ / Cont.',
      note: 'Factory/CFS cargo unloading (incl. 18% GST)',
    ),
    PortLogisticsItem(
      name: 'Weighment Charges',
      amount40Hc: 600.00,
      amount20Gp: 600.00,
      unit: '₹ / Cont.',
      note: 'Electronic weighbridge weight slip (Pipavav Port)',
    ),
  ];

  // Presets of popular export ports
  static const List<PortPreset> destinationPresets = [
    PortPreset(
      portName: 'Hai Phong',
      country: 'Vietnam',
      freight40HcUsd: 350.00,
      freight20GpUsd: 225.00,
      transitDays: '18 - 22 Days',
    ),
    PortPreset(
      portName: 'Jebel Ali / Dubai',
      country: 'UAE',
      freight40HcUsd: 450.00,
      freight20GpUsd: 300.00,
      transitDays: '5 - 7 Days',
    ),
    PortPreset(
      portName: 'Dammam / Jeddah',
      country: 'Saudi Arabia',
      freight40HcUsd: 600.00,
      freight20GpUsd: 400.00,
      transitDays: '8 - 12 Days',
    ),
    PortPreset(
      portName: 'Felixstowe / Rotterdam / Hamburg',
      country: 'Europe',
      freight40HcUsd: 1650.00,
      freight20GpUsd: 1100.00,
      transitDays: '25 - 32 Days',
    ),
    PortPreset(
      portName: 'New York / Savannah',
      country: 'USA',
      freight40HcUsd: 3200.00,
      freight20GpUsd: 2400.00,
      transitDays: '30 - 38 Days',
    ),
    PortPreset(
      portName: 'Port Klang',
      country: 'Malaysia',
      freight40HcUsd: 400.00,
      freight20GpUsd: 280.00,
      transitDays: '12 - 15 Days',
    ),
    PortPreset(
      portName: 'Jakarta / Surabaya',
      country: 'Indonesia',
      freight40HcUsd: 450.00,
      freight20GpUsd: 320.00,
      transitDays: '15 - 18 Days',
    ),
  ];

  // Inputs
  final double usdRate; // e.g. 88.00
  final bool is40Hc; // true for 40' HC (24 MT), false for 20' GP (14 MT)
  final String productName;
  final String productGrade;
  final double baseCostInr; // Ex-Factory ₹/kg (e.g. 197.00)
  final double profitMarginInr; // Desired profit ₹/kg (e.g. 10.00)
  final String originPort; // Fixed: Pipavav Port, Gujarat, India
  final String destinationPort; // e.g. Hai Phong, Vietnam
  final double oceanFreightUsd; // e.g. $350 for 40' HC, $225 for 20' GP
  final double marineInsuranceInr; // e.g. ₹2950 (incl. 18% GST)

  const ExportPriceCalculation({
    required this.usdRate,
    this.is40Hc = true,
    this.productName = 'White Onion Flakes (Sorted)',
    this.productGrade = 'A-Grade Optical Sorted',
    required this.baseCostInr,
    this.profitMarginInr = 10.00,
    this.originPort = 'Pipavav Port, Gujarat, India',
    this.destinationPort = 'Hai Phong, Vietnam',
    required this.oceanFreightUsd,
    this.marineInsuranceInr = 2950.00,
  });

  // Container Specs
  String get containerLabel => is40Hc ? "40' High Cube (HC)" : "20' General Purpose (GP)";
  double get payloadKg => is40Hc ? 24000.0 : 14000.0;
  double get payloadMt => is40Hc ? 24.0 : 14.0;

  // 1. Port Logistics
  double get portLogisticsTotalInr {
    return officialLogisticsItems.fold<double>(
      0.0,
      (sum, item) => sum + (is40Hc ? item.amount40Hc : item.amount20Gp),
    );
  }

  double get portLogisticsPerKgInr => portLogisticsTotalInr / payloadKg;

  // 2. FOB Pipavav
  double get fobPriceInrPerKg => baseCostInr + profitMarginInr + portLogisticsPerKgInr;
  double get fobPriceUsdPerKg => usdRate > 0 ? (fobPriceInrPerKg / usdRate) : 0.0;
  double get fobPriceUsdPerMt => fobPriceUsdPerKg * 1000.0;
  double get fobTotalContainerUsd => fobPriceUsdPerKg * payloadKg;

  // 3. Sea Freight & CFR Destination
  double get seaFreightGstInr => oceanFreightUsd * usdRate * 0.05;
  double get seaFreightTotalInr => oceanFreightUsd * usdRate * 1.05;
  double get seaFreightPerKgInr => seaFreightTotalInr / payloadKg;
  double get cfrPriceInrPerKg => fobPriceInrPerKg + seaFreightPerKgInr;
  double get cfrPriceUsdPerKg => usdRate > 0 ? (cfrPriceInrPerKg / usdRate) : 0.0;
  double get cfrPriceUsdPerMt => cfrPriceUsdPerKg * 1000.0;
  double get cfrTotalContainerUsd => cfrPriceUsdPerKg * payloadKg;

  // 4. Marine Cargo Insurance & CIF Destination
  double get insurancePerKgInr => marineInsuranceInr / payloadKg;
  double get cifPriceInrPerKg => cfrPriceInrPerKg + insurancePerKgInr;
  double get cifPriceUsdPerKg => usdRate > 0 ? (cifPriceInrPerKg / usdRate) : 0.0;
  double get cifPriceUsdPerMt => cifPriceUsdPerKg * 1000.0;
  double get cifTotalContainerUsd => cifPriceUsdPerKg * payloadKg;

  // Formatter helpers
  static final NumberFormat _currUsd = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final NumberFormat _rateUsd = NumberFormat.currency(symbol: '\$', decimalDigits: 3);
  static final NumberFormat _currInr = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  String get formattedFobUsdKg => _rateUsd.format(fobPriceUsdPerKg);
  String get formattedFobUsdMt => _currUsd.format(fobPriceUsdPerMt);
  String get formattedFobTotalUsd => _currUsd.format(fobTotalContainerUsd);

  String get formattedCfrUsdKg => _rateUsd.format(cfrPriceUsdPerKg);
  String get formattedCfrUsdMt => _currUsd.format(cfrPriceUsdPerMt);
  String get formattedCfrTotalUsd => _currUsd.format(cfrTotalContainerUsd);

  String get formattedCifUsdKg => _rateUsd.format(cifPriceUsdPerKg);
  String get formattedCifUsdMt => _currUsd.format(cifPriceUsdPerMt);
  String get formattedCifTotalUsd => _currUsd.format(cifTotalContainerUsd);

  String get formattedExFactoryInr => _currInr.format(baseCostInr);
  String get formattedLogisticsTotalInr => _currInr.format(portLogisticsTotalInr);
  String get formattedLogisticsPerKgInr => _currInr.format(portLogisticsPerKgInr);

  /// Generates a formal export quotation for WhatsApp / Email / Buyer messaging
  String generateFormalQuote({String buyerName = 'Valued Importer', String companyName = ''}) {
    final todayStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
    final validUntil = DateFormat('dd-MMM-yyyy').format(DateTime.now().add(const Duration(days: 7)));

    final greeting = companyName.isNotEmpty
        ? 'Dear $buyerName ($companyName),'
        : 'Dear $buyerName,';

    return '''
*AMAR FOODS - OFFICIAL EXPORT PRICE QUOTATION*
Date: $todayStr | Valid Until: $validUntil

$greeting

We are pleased to quote our official export prices for your inquiry:

📦 *Product Specifications:*
• Product: $productName
• Quality / Grade: $productGrade
• Origin: Mahuva, Gujarat, India
• Port of Loading: Pipavav Port, Gujarat, India
• Destination Port: $destinationPort
• Container Equipment: $containerLabel
• Payload Quantity: ${NumberFormat('#,##0').format(payloadKg)} kg (${payloadMt.toStringAsFixed(0)} Metric Tons)

💰 *Export Pricing Breakdown:*
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1️⃣ *FOB Pipavav Port:*
   • Unit Price: *$formattedFobUsdKg / kg* ($formattedFobUsdMt / MT)
   • Total FOB Value: *$formattedFobTotalUsd*

2️⃣ *CFR $destinationPort:*
   • Unit Price: *$formattedCfrUsdKg / kg* ($formattedCfrUsdMt / MT)
   • Total CFR Value: *$formattedCfrTotalUsd*

3️⃣ *CIF $destinationPort (All Inclusive):*
   • Unit Price: *$formattedCifUsdKg / kg* ($formattedCifUsdMt / MT)
   • Total CIF Contract Value: *$formattedCifTotalUsd*
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 *Commercial Terms:*
• Packaging: Standard export-grade Poly Bags inside Corrugated Cartons / PP Bags
• Quality Certification: Phytosanitary Certificate, Certificate of Origin, Fumigation Certificate, Lab COA
• Payment Terms: 30% Advance T/T, 70% against Scanned BL Copy (or Irrevocable Confirmed L/C at sight)
• Shipment: Prompt dispatch within 10-14 days from order confirmation

Please feel free to confirm if this quotation meets your schedule. We look forward to establishing a long-term partnership with your organization.

Best regards,
*Amar Foods Export Sales Team*
Mahuva, Bhavnagar, Gujarat, India
''';
  }
}
