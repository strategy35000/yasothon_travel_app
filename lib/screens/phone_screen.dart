import 'package:flutter/material.dart';
import 'package:yasothon_travel_app/widgets/gradient_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'สมุดโทรศัพท์',
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              color: Colors.white,
            ),
            indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.white,
            tabs: const [
              Tab(text: "สายด่วน"),
              Tab(text: "หมวดหมู่"),
              Tab(text: "หน่วยงาน/บุคคล"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // สายด่วน Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                EmergencyNumberCard(title: 'เหตุด่วนเหตุร้าย (ตำรวจ)', subtitle: 'แจ้งเหตุด่วน, อาชญากรรม', number: '191'),
                EmergencyNumberCard(title: 'เจ็บป่วยฉุกเฉิน', subtitle: 'เรียกรถพยาบาล, กู้ชีพ', number: '1669'),
                EmergencyNumberCard(title: 'ดับเพลิง', subtitle: 'แจ้งเหตุไฟไหม้, สัตว์เข้าบ้าน', number: '199'),
                EmergencyNumberCard(title: 'ตำรวจท่องเที่ยว', subtitle: 'เหตุด่วนสำหรับนักท่องเที่ยว', number: '1155'),
                EmergencyNumberCard(title: 'ตำรวจทางหลวง', subtitle: 'อุบัติเหตุบนทางหลวง', number: '1193'),
                EmergencyNumberCard(title: 'การทางพิเศษ', subtitle: 'อุบัติเหตุบนทางด่วน', number: '1543'),
                EmergencyNumberCard(title: 'ศูนย์ช่วยเหลือสังคม', subtitle: 'แจ้งคนหาย, ขอความช่วยเหลือ', number: '1300'),
                EmergencyNumberCard(title: 'ไฟฟ้าขัดข้อง (กทม./ปริมณฑล)', subtitle: 'การไฟฟ้านครหลวง', number: '1130'),
                EmergencyNumberCard(title: 'ไฟฟ้าขัดข้อง (ต่างจังหวัด)', subtitle: 'การไฟฟ้าส่วนภูมิภาค', number: '1129'),
                EmergencyNumberCard(title: 'ประปาขัดข้อง (กทม./ปริมณฑล)', subtitle: 'การประปานครหลวง', number: '1126'),
                EmergencyNumberCard(title: 'ประปาขัดข้อง (ต่างจังหวัด)', subtitle: 'การประปาส่วนภูมิภาค', number: '1125'),
              ],
            ),
            const Center(child: Text("หมวดหมู่")),
            const Center(child: Text("หน่วยงาน/บุคคล")),
          ],
        ),
      ),
    );
  }
}

class EmergencyNumberCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String number;

  const EmergencyNumberCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.number});

  // Function to launch phone call
  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Show error if unable to launch
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถโทรออกไปที่ $phoneNumber ได้')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _makePhoneCall(number, context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(number,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Icon(Icons.phone,
                  color: Theme.of(context).primaryColor, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

