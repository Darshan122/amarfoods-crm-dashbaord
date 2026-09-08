import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/product_price.dart';

class PricePdfService {
  static Future<Uint8List> generatePriceListPdf({
    required List<ProductPrice> prices,
    required String weekLabel,
    String validity = 'Valid for 7 Days Only',
  }) async {
    final pdf = pw.Document();

    // Load logo if available
    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/amar_foods_logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      logoImage = pw.MemoryImage(bytes);
    } catch (_) {}

    final todayStr = DateTime.now().toLocal().toString().split(' ')[0];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context ctx) => _buildHeader(logoImage, weekLabel, todayStr, validity),
        footer: (pw.Context ctx) => _buildFooter(ctx),
        build: (pw.Context ctx) {
          return [
            pw.SizedBox(height: 10),
            _buildBoldNotice(),
            pw.SizedBox(height: 10),
            _buildProductTable(prices),
            pw.SizedBox(height: 12),
            _buildCommercialTerms(),
            pw.SizedBox(height: 12),
            _buildSignature(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage? logoImage,
    String weekLabel,
    String todayStr,
    String validity,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              children: [
                if (logoImage != null) ...[
                  pw.Image(logoImage, width: 50, height: 50),
                  pw.SizedBox(width: 12),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AMAR FOODS',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('0F766E'), // Deep Teal
                      ),
                    ),
                    pw.Text(
                      'Manufacturer & Exporter of Dehydrated Foods & Agro Spices',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Mahuva - 364290, Gujarat, India | APEDA | FSSAI | BRC | Halal Certified',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F0FDFA'),
                border: pw.Border.all(color: PdfColor.fromHex('0F766E'), width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'WEEKLY EX-FACTORY PRICE LIST',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('0F766E'),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    weekLabel.isNotEmpty ? weekLabel : 'Current Week Offer',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                  ),
                  pw.Text(
                    'Basis: Ex-Factory Mahuva | Valid: 7 Days Only',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1.5, color: PdfColor.fromHex('0F766E')),
      ],
    );
  }

  static pw.Widget _buildBoldNotice() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('FEF3C7'), // Light Amber
        border: pw.Border.all(color: PdfColor.fromHex('D97706'), width: 1.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: 'IMPORTANT NOTE: ',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('92400E'),
              ),
            ),
            pw.TextSpan(
              text:
                  'All quoted prices are EX-FACTORY (Mahuva, Gujarat) rates in Indian Rupees (INR / Rs. per kg) and STRICTLY VALID FOR 7 DAYS ONLY from the date of issue.',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('78350F'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildProductTable(List<ProductPrice> prices) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(26), // Sr
        1: const pw.FlexColumnWidth(2.6), // Product
        2: const pw.FlexColumnWidth(1.6), // Grade
        3: const pw.FlexColumnWidth(1.5), // Packing
        4: const pw.FlexColumnWidth(1.2), // MOQ
        5: const pw.FlexColumnWidth(1.6), // Rate
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('0F766E')),
          children: [
            _cell('SR', isHeader: true, align: pw.TextAlign.center),
            _cell('PRODUCT NAME', isHeader: true),
            _cell('GRADE / SPEC', isHeader: true),
            _cell('PACKAGING', isHeader: true),
            _cell('MOQ', isHeader: true, align: pw.TextAlign.center),
            _cell('EX-FACTORY RATE (RS/KG)', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Table Rows
        ...prices.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value;
          final isEven = idx % 2 == 0;
          final rowBg = isEven ? PdfColors.white : PdfColor.fromHex('F8FAFC');

          final isINR = p.currency.contains('₹') || p.currency.toUpperCase().contains('INR');
          final priceStr = p.currentPrice > 0
              ? (isINR ? 'Rs. ${p.currentPrice.toStringAsFixed(0)} / kg' : '\$${p.currentPrice.toStringAsFixed(0)} / MT')
              : 'On Request';

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell('${idx + 1}', align: pw.TextAlign.center, fontSize: 8),
              _cell(p.name, isBold: true, fontSize: 8),
              _cell(p.grade.isNotEmpty ? p.grade : '-', fontSize: 7.5),
              _cell(p.packing.isNotEmpty ? p.packing : '20/25 kg Bag', fontSize: 7.5),
              _cell(p.moq.isNotEmpty ? p.moq : '1000 kg', align: pw.TextAlign.center, fontSize: 7.5),
              _cell(priceStr, align: pw.TextAlign.right, isBold: true, fontSize: 8.5, color: PdfColor.fromHex('0F766E')),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 7.5 : fontSize,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : (color ?? PdfColors.black),
        ),
      ),
    );
  }

  static pw.Widget _buildCommercialTerms() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('F8FAFC'),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'STANDARD COMMERCIAL TERMS & CONDITIONS',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('0F766E'),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _termItem('Price Basis', 'Ex-Factory Mahuva (Gujarat, India) - GST & Freight extra as applicable'),
                    _termItem('Price Validity', 'Strictly valid for 7 days only from the date of issue'),
                    _termItem('Payment Terms', '30% Advance TT & balance against dispatch / BL copy or 100% LC at Sight'),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _termItem('Delivery Lead Time', 'Within 7 - 12 days of confirmed purchase order'),
                    _termItem('Quality Standards', '100% Pure Dehydrated Products; In-house COA included (BRC / FSSAI / Halal)'),
                    _termItem('Dispatch & Transport', 'Available across all India or Mundra/Pipavav seaport on actual freight basis'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _termItem(String title, String desc) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3.5,
            height: 3.5,
            margin: const pw.EdgeInsets.only(top: 3.5, right: 5),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('0F766E'),
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '$title: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColors.black),
                  ),
                  pw.TextSpan(
                    text: desc,
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignature() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Issued by Export Sales Division:',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Darshan Zalavadiya',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0F766E')),
            ),
            pw.Text('Export Sales Executive | Amar Foods, India', style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text('Mob / WhatsApp: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColor.fromHex('0F766E'))),
                pw.Text('+91 7284088737', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
              ],
            ),
            pw.SizedBox(height: 1.5),
            pw.Row(
              children: [
                pw.Text('Email: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColor.fromHex('0F766E'))),
                pw.Text('export@amarfoods.in', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                pw.Text('   |   ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey400)),
                pw.Text('Web: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColor.fromHex('0F766E'))),
                pw.Text('https://amarfoods.in/', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
              ],
            ),
          ],
        ),
        pw.Container(
          width: 140,
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              pw.Text('AUTHORIZED SIGNATORY', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 18),
              pw.Text('Amar Foods (Export Dept.)', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0F766E'))),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Amar Foods | Confidential Quotation for Intended Recipient',
              style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  /// 1-Click trigger to download or preview the generated PDF in the browser
  static Future<void> downloadOrPrintPriceList({
    required List<ProductPrice> prices,
    required String weekLabel,
    String validity = '7 Days from Issue Date',
  }) async {
    final pdfBytes = await generatePriceListPdf(
      prices: prices,
      weekLabel: weekLabel,
      validity: validity,
    );

    final cleanFileName = 'Amar_Foods_Export_Price_List_${weekLabel.replaceAll(RegExp(r'[^\w\d]'), '_')}.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: cleanFileName,
    );
  }
}
