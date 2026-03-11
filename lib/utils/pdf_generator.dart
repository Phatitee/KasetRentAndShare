import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/rental_contract_model.dart';

class PdfGenerator {
  static Future<void> generateContractPdf(RentalContractModel contract) async {
    final pdf = pw.Document();

    final ttf = await PdfGoogleFonts.sarabunRegular();
    final boldTtf = await PdfGoogleFonts.sarabunBold();

    // Download images
    pw.MemoryImage? ownerSignature;
    pw.MemoryImage? renterSignature;
    pw.MemoryImage? paymentSlip;
    
    pw.MemoryImage? ownerPickupPhoto;
    pw.MemoryImage? renterPickupPhoto;
    pw.MemoryImage? ownerReturnPhoto;
    pw.MemoryImage? renterReturnPhoto;

    if (contract.ownerSignatureUrl != null) {
      ownerSignature = await _downloadImage(contract.ownerSignatureUrl!);
    }
    if (contract.renterSignatureUrl != null) {
      renterSignature = await _downloadImage(contract.renterSignatureUrl!);
    }
    if (contract.paymentSlipUrl != null) {
      paymentSlip = await _downloadImage(contract.paymentSlipUrl!);
    }
    
    // Pickup Photos
    if (contract.ownerPickupPhotoUrl != null) {
      ownerPickupPhoto = await _downloadImage(contract.ownerPickupPhotoUrl!);
    }
    if (contract.renterPickupPhotoUrl != null) {
      renterPickupPhoto = await _downloadImage(contract.renterPickupPhotoUrl!);
    }
    
    // Return Photos
    if (contract.ownerReturnPhotoUrl != null) {
      ownerReturnPhoto = await _downloadImage(contract.ownerReturnPhotoUrl!);
    }
    if (contract.renterReturnPhotoUrl != null) {
      renterReturnPhoto = await _downloadImage(contract.renterReturnPhotoUrl!);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (pw.Context context) {
          return [
            _buildHeader(contract, boldTtf),
            pw.SizedBox(height: 15),
            _buildPartiesInfo(contract, boldTtf),
            pw.SizedBox(height: 15),
            _buildContractInfo(contract, boldTtf),
            pw.SizedBox(height: 15),
            _buildFinancialInfo(contract, boldTtf, paymentSlip),
            pw.SizedBox(height: 20),
            _buildEvidenceSection(
              'หลักฐานการส่งมอบ (Pickup Evidence)', 
              contract.pickupConfirmedAt, 
              ownerPickupPhoto, 
              renterPickupPhoto,
              boldTtf,
              contract.ownerName,
              contract.renterName,
            ),
            pw.SizedBox(height: 20),
            _buildEvidenceSection(
              'หลักฐานการคืนสินค้า (Return Evidence)', 
              contract.returnConfirmedAt, 
              ownerReturnPhoto, 
              renterReturnPhoto,
              boldTtf,
              contract.ownerName,
              contract.renterName,
            ),
            pw.SizedBox(height: 30),
            _buildSignatures(contract, boldTtf, ownerSignature, renterSignature),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Contract_${contract.id.substring(0, 8)}.pdf',
    );
  }

  static Future<pw.MemoryImage?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }

  static pw.Widget _buildHeader(RentalContractModel contract, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('หนังสือสัญญาเช่าทรัพย์สินและหลักฐานการส่งมอบ', style: pw.TextStyle(font: boldFont, fontSize: 18)),
        pw.SizedBox(height: 5),
        pw.Text('Contract ID: ${contract.id.toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildPartiesInfo(RentalContractModel contract, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('คู่สัญญา (Parties)', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Expanded(child: pw.Text('ผู้ให้เช่า: ${contract.ownerName}')),
            pw.Expanded(child: pw.Text('ผู้เช่า: ${contract.renterName}')),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildContractInfo(RentalContractModel contract, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('รายละเอียดการเช่า (Rental Details)', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        pw.SizedBox(height: 5),
        pw.Text('สินค้า: ${contract.itemName}', style: pw.TextStyle(font: boldFont)),
        pw.Text('ระยะเวลา: ${DateFormat('d MMM yyyy').format(contract.startDate)} ถึง ${DateFormat('d MMM yyyy').format(contract.endDate)} (${contract.rentalDays} วัน)'),
      ],
    );
  }

  static pw.Widget _buildFinancialInfo(RentalContractModel contract, pw.Font boldFont, pw.MemoryImage? slip) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ข้อมูลการชำระเงิน (Financial Details)', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        pw.SizedBox(height: 5),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ยอดรวมค่าเช่า (Total Rental)'),
                  pw.Text('THB ${contract.totalAmount.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('เงินมัดจำ (Deposit)'),
                  pw.Text('THB ${contract.deposit.toStringAsFixed(2)}'),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('สถานะการชำระเงิน'),
                  pw.Text(contract.paymentStatus == 'paid' ? 'ชำระเงินแล้ว' : 'รอดำเนินการ'),
                ],
              ),
            ],
          ),
        ),
        if (slip != null) ...[
          pw.SizedBox(height: 10),
          pw.Text('หลักฐานการโอนเงิน (Payment Slip):', style: pw.TextStyle(font: boldFont, fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Center(child: pw.Image(slip, height: 200)),
        ],
      ],
    );
  }

  static pw.Widget _buildEvidenceSection(
    String title, 
    DateTime? date, 
    pw.MemoryImage? ownerPhoto, 
    pw.MemoryImage? renterPhoto,
    pw.Font boldFont,
    String ownerName,
    String renterName,
  ) {
    if (date == null && ownerPhoto == null && renterPhoto == null) return pw.SizedBox();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 14)),
        pw.SizedBox(height: 5),
        if (date != null)
          pw.Text('ยืนยันเสร็จสมบูรณ์เมื่อ: ${DateFormat('d MMM yyyy, HH:mm').format(date)}'),
        pw.SizedBox(height: 10),
        
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            // Owner Photo
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text('รูปจากผู้ให้เช่า ($ownerName)', style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 5),
                  if (ownerPhoto != null)
                    pw.Image(ownerPhoto, height: 120)
                  else
                    pw.Container(
                      height: 120,
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Center(child: pw.Text('ไม่มีรูป', style: const pw.TextStyle(fontSize: 8))),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            // Renter Photo
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text('รูปจากผู้เช่า ($renterName)', style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 5),
                  if (renterPhoto != null)
                    pw.Image(renterPhoto, height: 120)
                  else
                    pw.Container(
                      height: 120,
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Center(child: pw.Text('ไม่มีรูป', style: const pw.TextStyle(fontSize: 8))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSignatures(RentalContractModel contract, pw.Font boldFont, pw.MemoryImage? ownerSig, pw.MemoryImage? renterSig) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSignatureCol('ผู้ให้เช่า', contract.ownerName, ownerSig, boldFont),
        _buildSignatureCol('ผู้เช่า', contract.renterName, renterSig, boldFont),
      ],
    );
  }

  static pw.Widget _buildSignatureCol(String title, String name, pw.MemoryImage? sig, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Text(title, style: pw.TextStyle(font: boldFont)),
        pw.SizedBox(height: 5),
        if (sig != null) pw.Image(sig, width: 80, height: 40) else pw.SizedBox(height: 40),
        pw.Text('_____________________'),
        pw.Text(name),
      ],
    );
  }
}
