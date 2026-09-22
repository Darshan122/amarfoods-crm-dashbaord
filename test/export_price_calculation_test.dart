import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_crm_app/models/export_price_calculation.dart';

void main() {
  group('ExportPriceCalculation Engine Tests', () {
    test('40 HC Pipavav Port logistics and export calculation', () {
      final calc = ExportPriceCalculation(
        usdRate: 88.00,
        is40Hc: true,
        productName: 'White Onion Flakes (Sorted)',
        productGrade: 'A-Grade Optical Sorted',
        baseCostInr: 197.00,
        profitMarginInr: 10.00,
        originPort: 'Pipavav Port, Gujarat, India',
        destinationPort: 'Hai Phong, Vietnam',
        oceanFreightUsd: 350.00,
        marineInsuranceInr: 2950.00,
      );

      // Verify container specs
      expect(calc.payloadKg, 24000.0);
      expect(calc.payloadMt, 24.0);

      // Verify Port Logistics (Pipavav Port - 12 Line Items)
      expect(calc.portLogisticsTotalInr, closeTo(81493.80, 0.01));
      expect(calc.portLogisticsPerKgInr, closeTo(3.395575, 0.001));

      // Verify FOB Pipavav
      final expectedFobInr = 197.00 + 10.00 + (81493.80 / 24000.0);
      expect(calc.fobPriceInrPerKg, closeTo(expectedFobInr, 0.01));
      expect(calc.fobPriceUsdPerKg, closeTo(expectedFobInr / 88.00, 0.001));
      expect(calc.fobPriceUsdPerMt, closeTo((expectedFobInr / 88.00) * 1000, 0.1));
      expect(calc.fobTotalContainerUsd, closeTo((expectedFobInr / 88.00) * 24000, 1.0));

      // Verify Sea Freight ($350 @ 88 + 5% GST = ₹32,340)
      final expectedFreightInr = 350.00 * 88.00 * 1.05;
      expect(calc.seaFreightTotalInr, closeTo(expectedFreightInr, 0.01));
      expect(calc.seaFreightPerKgInr, closeTo(expectedFreightInr / 24000.0, 0.001));

      // Verify CFR Hai Phong
      final expectedCfrInr = expectedFobInr + (expectedFreightInr / 24000.0);
      expect(calc.cfrPriceInrPerKg, closeTo(expectedCfrInr, 0.01));
      expect(calc.cfrPriceUsdPerKg, closeTo(expectedCfrInr / 88.00, 0.001));

      // Verify Marine Insurance (₹2,950 / 24,000 kg)
      final expectedInsPerKg = 2950.00 / 24000.0;
      expect(calc.insurancePerKgInr, closeTo(expectedInsPerKg, 0.001));

      // Verify CIF Hai Phong
      final expectedCifInr = expectedCfrInr + expectedInsPerKg;
      expect(calc.cifPriceInrPerKg, closeTo(expectedCifInr, 0.01));
      expect(calc.cifPriceUsdPerKg, closeTo(expectedCifInr / 88.00, 0.001));
      expect(calc.cifTotalContainerUsd, closeTo((expectedCifInr / 88.00) * 24000, 1.0));
    });

    test('20 GP Pipavav Port logistics and export calculation', () {
      final calc20 = ExportPriceCalculation(
        usdRate: 88.00,
        is40Hc: false,
        productName: 'White Onion Flakes (Sorted)',
        productGrade: 'A-Grade Optical Sorted',
        baseCostInr: 197.00,
        profitMarginInr: 10.00,
        originPort: 'Pipavav Port, Gujarat, India',
        destinationPort: 'Hai Phong, Vietnam',
        oceanFreightUsd: 225.00,
        marineInsuranceInr: 2950.00,
      );

      // Verify container specs
      expect(calc20.payloadKg, 14000.0);
      expect(calc20.payloadMt, 14.0);

      // Verify Port Logistics (Pipavav Port - 12 Line Items)
      expect(calc20.portLogisticsTotalInr, closeTo(68773.40, 0.01));
      expect(calc20.portLogisticsPerKgInr, closeTo(4.912385, 0.001));

      // Higher logistics per kg in 20' GP than 40' HC
      expect(calc20.portLogisticsPerKgInr > 3.40, isTrue);
    });

    test('Daily USD Rate Dynamic Recalculation', () {
      final calcAt88 = ExportPriceCalculation(
        usdRate: 88.00,
        baseCostInr: 197.00,
        oceanFreightUsd: 350.00,
      );
      final calcAt90 = ExportPriceCalculation(
        usdRate: 90.00,
        baseCostInr: 197.00,
        oceanFreightUsd: 350.00,
      );

      // USD price per kg drops when INR depreciates (higher USD rate)
      expect(calcAt90.cifPriceUsdPerKg < calcAt88.cifPriceUsdPerKg, isTrue);
    });

    test('Formal Quotation Generator creates professional output', () {
      final calc = ExportPriceCalculation(
        usdRate: 88.00,
        baseCostInr: 197.00,
        oceanFreightUsd: 350.00,
      );
      final quote = calc.generateFormalQuote(buyerName: 'John Doe', companyName: 'Global Spices LLC');

      expect(quote.contains('AMAR FOODS - OFFICIAL EXPORT PRICE QUOTATION'), isTrue);
      expect(quote.contains('John Doe (Global Spices LLC)'), isTrue);
      expect(quote.contains('FOB Pipavav Port:'), isTrue);
      expect(quote.contains('CFR Hai Phong, Vietnam:'), isTrue);
      expect(quote.contains('CIF Hai Phong, Vietnam (All Inclusive):'), isTrue);
      expect(quote.contains('Phytosanitary Certificate'), isTrue);
    });
  });
}
