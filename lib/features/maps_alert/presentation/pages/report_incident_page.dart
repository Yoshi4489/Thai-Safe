import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:thai_safe/features/authentication/presentation/signup_phone_page.dart'; 
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart'; 
import 'package:thai_safe/features/incidents/controllers/incident_controller.dart'; 

class ReportIncidentPage extends ConsumerStatefulWidget {
  final LatLng currentLocation;

  const ReportIncidentPage({
    super.key,
    this.currentLocation = const LatLng(13.7649, 100.5383),
  });

  @override
  ConsumerState<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends ConsumerState<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategory;
  File? _imageFile;
  
  // --- Controllers หลัก ---
  final TextEditingController _titleController = TextEditingController(); 
  final TextEditingController _detailController = TextEditingController();
  
  // --- ตัวแปรสำหรับแต่ละประเภท ---
  bool _floodHasPeopleWaiting = false; 
  final TextEditingController _floodPeopleCountController = TextEditingController();
  final TextEditingController _floodMedicationController = TextEditingController();
  final TextEditingController _floodDiseaseController = TextEditingController();
  bool _floodHasElectricity = false;
  bool _floodHasBedridden = false;
  bool _floodNeedMeds = false;
  bool _floodSevereDisease = false;
  String _floodWaterCurrent = 'สงบ';
  String _floodBoatAccess = 'ไม่ได้';
  String _floodSupplies = 'ไม่มีเลย';

  String _fireType = 'บ้าน/อาคาร';
  String _fireStatus = 'ควันเล็กน้อย';
  bool _fireHasTrapped = false;
  final TextEditingController _fireTrappedCountCtrl = TextEditingController();
  final TextEditingController _fireFloorsCtrl = TextEditingController();
  String _fireRisk = 'ไม่มี';
  String _fireWaterSource = 'ไม่มี';
  Map<String, bool> _fireNeeds = {
    'ถังดับเพลิง': false, 'รถดับเพลิง': false, 'รถพยาบาล': false, 'กู้ภัยที่สูง (รถกระเช้า)': false,
  };

  String _eqFeeling = 'สั่นสะเทือนเล็กน้อย';
  String _eqDamage = 'ไม่มี';
  bool _eqHasTrapped = false;
  final TextEditingController _eqTrappedCountCtrl = TextEditingController();
  String _eqRisk = 'ไม่มีความเสี่ยงต่อเนื่อง';
  Map<String, bool> _eqUtilities = {
    'ไฟฟ้าดับ': false, 'ท่อประปาแตก': false, 'แก๊สรั่ว': false,
  };
  Map<String, bool> _eqNeeds = {
    'ทีมค้นหา (K9/USAR)': false, 'หน่วยแพทย์': false, 'อาหาร/ที่พักชั่วคราว': false,
  };

  String _chemChar = 'กลิ่นฉุนรุนแรง';
  String _chemColor = 'ใส/ไม่มีสี';
  String _chemSymptom = 'แสบตา/ผิวหนัง';
  String _chemWind = 'ลมสงบ';
  String _chemArea = 'ภายในอาคาร';
  bool _chemHasInjured = false; 
  final TextEditingController _chemInjuredCtrl = TextEditingController();
  Map<String, bool> _chemNeeds = {
    'ชุด PPE/กู้ภัยสารเคมี': false, 'รถพยาบาล': false, 'ประกาศอพยพ': false,
  };

  String _violType = 'ทะเลาะวิวาท';
  String _violWeapon = 'ไม่มี/ไม่เห็น'; 
  String _violStatus = 'ยังอยู่ในพื้นที่';
  final TextEditingController _violFledVehicleCtrl = TextEditingController();
  bool _violHasInjured = false; 
  final TextEditingController _violInjuredCtrl = TextEditingController();
  String _violInjuryType = 'บาดเจ็บเล็กน้อย';
  String _violSafety = 'กำลังซ่อนตัว';
  final TextEditingController _violSuspectCtrl = TextEditingController();
  Map<String, bool> _violNeeds = {
    'ตำรวจ': false, 'รถพยาบาล': false, 'หน่วยกู้ภัย': false,
  };

  bool _otherHasAffected = false; 
  final TextEditingController _otherAffectedCtrl = TextEditingController();
  Map<String, bool> _otherNeeds = {
    'แพทย์/รถพยาบาล': false, 'ตำรวจ': false, 'กู้ภัยทางถนน': false, 'กู้ภัยทั่วไป': false,
  };

  final ImagePicker _picker = ImagePicker();
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;

  String _urgency = 'รอได้';

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _floodPeopleCountController.dispose();
    _floodMedicationController.dispose();
    _floodDiseaseController.dispose();
    _fireTrappedCountCtrl.dispose();
    _fireFloorsCtrl.dispose();
    _eqTrappedCountCtrl.dispose();
    _chemInjuredCtrl.dispose();
    _violFledVehicleCtrl.dispose();
    _violInjuredCtrl.dispose();
    _violSuspectCtrl.dispose();
    _otherAffectedCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _selectedLocation = LatLng(position.latitude, position.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
    }
  }

  final List<Map<String, dynamic>> _categories = [
    {'id': 'fire', 'label': 'ไฟไหม้', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'id': 'flood', 'label': 'น้ำท่วม', 'icon': Icons.flood, 'color': Colors.blueAccent},
    {'id': 'collapse', 'label': 'แผ่นดินไหว', 'icon': Icons.domain_disabled, 'color': Colors.brown},
    {'id': 'chemical', 'label': 'สารเคมีรั่ว', 'icon': Icons.science, 'color': Colors.purple},
    {'id': 'violence', 'label': 'เหตุร้าย', 'icon': Icons.warning_amber, 'color': Colors.red},
    {'id': 'other', 'label': 'อื่นๆ', 'icon': Icons.sos, 'color': Colors.grey},
  ];

  Widget _buildUrgencyPicker() {
    final levels = ['รอได้', 'ด่วนมาก', 'ถึงแก่ชีวิต'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        _sectionHeader('ระดับความเร่งด่วน (Triage)'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: levels.map((level) {
              bool isSelected = _urgency == level;
              Color color = level == 'ถึงแก่ชีวิต' ? Colors.red : (level == 'ด่วนมาก' ? Colors.orange : Colors.green);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(child: Text(level, style: const TextStyle(fontSize: 12))),
                    selected: isSelected,
                    selectedColor: color.withOpacity(0.2),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
                    onSelected: (val) => setState(() => _urgency = level),
                    labelStyle: TextStyle(
                      color: isSelected ? color : Colors.black54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String currentValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        value: currentValue,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, {String? suffix, bool validateNonZero = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autovalidateMode: validateNonZero ? AutovalidateMode.always : AutovalidateMode.disabled,
        validator: (value) {
          if (validateNonZero) {
            if (value == null || value.trim().isEmpty) return 'กรุณาระบุจำนวน';
            final intVal = int.tryParse(value);
            if (intVal == null || intVal <= 0) return 'จำนวนต้องมากกว่า 0';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, bool val, Function(bool?) onChanged) => CheckboxListTile(
    title: Text(title, style: const TextStyle(fontSize: 14)), 
    value: val, 
    onChanged: onChanged, 
    activeColor: Colors.redAccent,
    dense: true, 
    controlAffinity: ListTileControlAffinity.leading,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );

  Widget _buildDynamicFields() {
    if (_selectedCategory == null) return const SizedBox.shrink();
    List<Widget> children = [];

    switch (_selectedCategory) {
      case 'flood':
        children.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHeader('สภาพเหตุ และการช่วยเหลือ'),
            _buildSwitch('มีผู้รอรับความช่วยเหลือ หรือไม่', _floodHasPeopleWaiting, (v) => setState(() => _floodHasPeopleWaiting = v)),
            if (_floodHasPeopleWaiting) 
              _buildNumberField('จำนวนผู้รอรับความช่วยเหลือ (ประมาณ)', _floodPeopleCountController, suffix: 'คน', validateNonZero: true),
            _buildSwitch('มีกระแสไฟฟ้า หรือไม่', _floodHasElectricity, (v) => setState(() => _floodHasElectricity = v)),
            _buildSwitch('มีผู้ป่วยติดเตียง หรือไม่', _floodHasBedridden, (v) => setState(() => _floodHasBedridden = v)),
            const SizedBox(height: 8),
            _sectionLabel('กระแสน้ำ'),
            _buildSegmented(['สงบ', 'ปานกลาง', 'แรงมาก'], _floodWaterCurrent, (v) => setState(() => _floodWaterCurrent = v)),
            const SizedBox(height: 12),
            _sectionLabel('เรือสามารถเข้าไปได้ หรือไม่'),
            _buildSegmented(['ไม่ได้', 'ไม่แน่ใจ', 'ได้'], _floodBoatAccess, (v) => setState(() => _floodBoatAccess = v)),
             const SizedBox(height: 12),
            _sectionLabel('อาหาร และน้ำมีเพียงพอ หรือไม่'),
            _buildSegmented(['ไม่มีเลย', 'พอมี', 'เพียงพอ'], _floodSupplies, (v) => setState(() => _floodSupplies = v)),
            const Divider(height: 24),
            _sectionLabel('ข้อมูลทางการแพทย์เพิ่มเติม'),
            _buildSwitch('มีผู้ต้องการยาประจำตัว หรือไม่', _floodNeedMeds, (v) => setState(() => _floodNeedMeds = v)),
            if (_floodNeedMeds) _buildTextField('โปรดระบุชื่อยา...', _floodMedicationController),
            _buildSwitch('มีผู้ที่มีโรคประจำตัวรุนแรง หรือไม่', _floodSevereDisease, (v) => setState(() => _floodSevereDisease = v)),
            if (_floodSevereDisease) _buildTextField('โปรดระบุชื่อโรค...', _floodDiseaseController),
          ]));
        break;
      case 'fire':
        children.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader('ข้อมูลการเพลิงไหม้'),
          _buildDropdown('ประเภทของไฟ', ['บ้าน/อาคาร', 'โรงงาน/สารเคมี', 'หญ้า/ป่า', 'ยานพาหนะ'], _fireType, (v) => setState(() => _fireType = v!)),
          _sectionLabel('สถานะปัจจุบัน'),
          _buildSegmented(['ควันเล็กน้อย', 'ไฟลามหนัก', 'คุมเพลิงได้'], _fireStatus, (v) => setState(() => _fireStatus = v)),
          _buildSwitch('มีคนติดอยู่ในพื้นที่ หรือไม่', _fireHasTrapped, (v) => setState(() => _fireHasTrapped = v)),
          if (_fireHasTrapped) _buildNumberField('จำนวนผู้ติดอยู่ (คน)', _fireTrappedCountCtrl, validateNonZero: true),
          if (_fireType == 'บ้าน/อาคาร' || _fireType == 'โรงงาน/สารเคมี')
            _buildNumberField('ความสูงของอาคาร (ชั้น)', _fireFloorsCtrl),
          _buildDropdown('จุดเสี่ยงใกล้เคียง', ['ไม่มี', 'ปั๊มน้ำมัน', 'แหล่งสารเคมี', 'เสาไฟฟ้าแรงสูง'], _fireRisk, (v) => setState(() => _fireRisk = v!)),
          _sectionLabel('แหล่งน้ำใกล้เคียง'),
          _buildSegmented(['มีประปา/หัวแดง', 'มีคลอง', 'ไม่มี'], _fireWaterSource, (v) => setState(() => _fireWaterSource = v)),
          const Divider(height: 24),
          _sectionLabel('ความต้องการเร่งด่วน'),
          ..._fireNeeds.keys.map((key) => _buildCheckbox(key, _fireNeeds[key]!, (v) => setState(() => _fireNeeds[key] = v ?? false))),
        ]));
        break;
      case 'collapse': 
        children.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader('สถานการณ์แผ่นดินไหว/อาคารถล่ม'),
          _buildDropdown('ความรู้สึกขณะเกิด', ['ไม่รู้สึก', 'สั่นสะเทือนเล็กน้อย', 'ข้าวของตกหล่น', 'ทรงตัวลำบาก'], _eqFeeling, (v) => setState(() => _eqFeeling = v!)),
          _buildDropdown('ความเสียหายของอาคาร', ['ไม่มี', 'ผนังร้าวเล็กน้อย', 'โครงสร้างทรุด/พัง', 'ถล่มทั้งหมด'], _eqDamage, (v) => setState(() => _eqDamage = v!)),
          _buildSwitch('มีคนติดใต้ซากอาคาร หรือไม่', _eqHasTrapped, (v) => setState(() => _eqHasTrapped = v)),
          if (_eqHasTrapped) _buildNumberField('จำนวนผู้ติดอยู่ (คน)', _eqTrappedCountCtrl, validateNonZero: true),
          _buildDropdown('ความเสี่ยงต่อเนื่อง', ['ไม่มีความเสี่ยงต่อเนื่อง', 'ได้ยินเสียงอาคารลั่น', 'อยู่ใกล้หน้าผา/ดินสไลด์', 'อยู่ใกล้ชายฝั่ง (เสี่ยงสึนามิ)'], _eqRisk, (v) => setState(() => _eqRisk = v!)),
          const Divider(height: 24),
          _sectionLabel('สถานะสาธารณูปโภค'),
          ..._eqUtilities.keys.map((key) => _buildCheckbox(key, _eqUtilities[key]!, (v) => setState(() => _eqUtilities[key] = v ?? false))),
          const Divider(height: 24),
          _sectionLabel('ความต้องการเร่งด่วน'),
          ..._eqNeeds.keys.map((key) => _buildCheckbox(key, _eqNeeds[key]!, (v) => setState(() => _eqNeeds[key] = v ?? false))),
        ]));
        break;
      case 'chemical':
        children.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader('ข้อมูลสารเคมีรั่วไหล'),
          _buildDropdown('ลักษณะสิ่งที่พบ', ['กลุ่มควัน', 'กลิ่นฉุนรุนแรง', 'ของเหลวรั่วไหล', 'มีเสียงระเบิด'], _chemChar, (v) => setState(() => _chemChar = v!)),
          _sectionLabel('สีของควัน/สารเคมี'),
          _buildSegmented(['ใส/ไม่มีสี', 'ขาว', 'เหลือง/ส้ม', 'ดำ'], _chemColor, (v) => setState(() => _chemColor = v)),
          _sectionLabel('ทิศทางลม'),
          _buildSegmented(['ลมสงบ', 'พัดเข้าชุมชน', 'พัดออกชุมชน'], _chemWind, (v) => setState(() => _chemWind = v)),
          _sectionLabel('พื้นที่ได้รับผลกระทบ'),
          _buildSegmented(['ภายในอาคาร', 'รัศมี 500ม.', 'รัศมีเกิน 1กม.'], _chemArea, (v) => setState(() => _chemArea = v)),
          const Divider(height: 12),
          _buildSwitch('มีผู้ได้รับบาดเจ็บ หรือไม่', _chemHasInjured, (v) => setState(() => _chemHasInjured = v)),
          if (_chemHasInjured) ...[
            _buildNumberField('จำนวนผู้ได้รับบาดเจ็บ (คน)', _chemInjuredCtrl, validateNonZero: true),
            _buildDropdown('อาการของผู้บาดเจ็บ', ['แสบตา/ผิวหนัง', 'หายใจไม่ออก', 'หมดสติ', 'อาเจียน'], _chemSymptom, (v) => setState(() => _chemSymptom = v!)),
          ],
          const Divider(height: 24),
          _sectionLabel('ความต้องการเร่งด่วน'),
          ..._chemNeeds.keys.map((key) => _buildCheckbox(key, _chemNeeds[key]!, (v) => setState(() => _chemNeeds[key] = v ?? false))),
        ]));
        break;
      case 'violence':
        children.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader('สถานการณ์เหตุร้าย/อาชญากรรม'),
          _buildDropdown('ประเภทเหตุ', ['ทำร้ายร่างกาย', 'วิ่งราว/ชิงทรัพย์', 'ทะเลาะวิวาท', 'กราดยิง/จับตัวประกัน'], _violType, (v) => setState(() => _violType = v!)),
          _buildDropdown('อาวุธที่พบ', ['ไม่มี/ไม่เห็น', 'มีด/ของมีคม', 'ปืน', 'ระเบิด'], _violWeapon, (v) => setState(() => _violWeapon = v!)),
          _buildDropdown('สถานะผู้ก่อเหตุ', ['ยังอยู่ในพื้นที่', 'หลบหนีไปแล้ว', 'ไม่ทราบ'], _violStatus, (v) => setState(() => _violStatus = v!)),
          if (_violStatus == 'หลบหนีไปแล้ว') _buildTextField('พาหนะที่ใช้หลบหนี / ป้ายทะเบียน', _violFledVehicleCtrl, hint: 'เช่น มอเตอร์ไซค์สีแดง...'),
          _buildTextField('รูปพรรณสันฐานผู้ก่อเหตุ', _violSuspectCtrl, hint: 'เสื้อผ้าหน้าผม...'),
          const Divider(height: 12),
          _buildSwitch('มีผู้ได้รับบาดเจ็บ หรือไม่', _violHasInjured, (v) => setState(() => _violHasInjured = v)),
          if (_violHasInjured) ...[
            _buildNumberField('จำนวนผู้บาดเจ็บ (คน)', _violInjuredCtrl, validateNonZero: true),
            _buildDropdown('อาการบาดเจ็บหลัก', ['แผลถูกฟัน/ยิง', 'หมดสติ', 'บาดเจ็บเล็กน้อย'], _violInjuryType, (v) => setState(() => _violInjuryType = v!)),
          ],
          const Divider(height: 12),
          _sectionLabel('ความปลอดภัยของคุณ'),
          _buildSegmented(['ปลอดภัยแล้ว', 'กำลังซ่อนตัว', 'กำลังเผชิญหน้า'], _violSafety, (v) => setState(() => _violSafety = v)),
          const Divider(height: 24),
          _sectionLabel('ความต้องการเร่งด่วน'),
          ..._violNeeds.keys.map((key) => _buildCheckbox(key, _violNeeds[key]!, (v) => setState(() => _violNeeds[key] = v ?? false))),
        ]));
        break;
      case 'other':
        children.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader('เหตุฉุกเฉินอื่นๆ'),
          _buildSwitch('มีผู้ได้รับผลกระทบ หรือไม่', _otherHasAffected, (v) => setState(() => _otherHasAffected = v)),
          if (_otherHasAffected) _buildNumberField('จำนวนผู้ได้รับผลกระทบ (คน)', _otherAffectedCtrl, validateNonZero: true),
          const Divider(height: 24),
          _sectionLabel('ความต้องการเร่งด่วน'),
          ..._otherNeeds.keys.map((key) => _buildCheckbox(key, _otherNeeds[key]!, (v) => setState(() => _otherNeeds[key] = v ?? false))),
        ]));
        break;
    }

    children.add(_buildUrgencyPicker());
    Color bgAlertColor = _urgency == 'ถึงแก่ชีวิต' ? Colors.red.withOpacity(0.1) : (_urgency == 'ด่วนมาก' ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.05));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgAlertColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _urgency == 'ถึงแก่ชีวิต' ? Colors.red : (_urgency == 'ด่วนมาก' ? Colors.orange : Colors.blue.shade200), width: 1.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _sectionHeader(String title) => ListTile(leading: const Icon(Icons.analytics_outlined, color: Colors.redAccent), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)));
  Widget _sectionLabel(String label) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));
  Widget _buildSwitch(String title, bool val, Function(bool) onChanged) => SwitchListTile(title: Text(title, style: const TextStyle(fontSize: 14)), value: val, onChanged: onChanged, activeColor: Colors.redAccent, dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16));
  Widget _buildSegmented(List<String> opts, String selected, Function(String) onSelect) {
    final currentSelection = opts.contains(selected) ? selected : opts.first;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: double.infinity, child: SegmentedButton<String>(segments: opts.map((o) => ButtonSegment(value: o, label: Text(o, style: const TextStyle(fontSize: 12)))).toList(), selected: {currentSelection}, onSelectionChanged: (v) => onSelect(v.first), style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact))));
  }

  // ==========================================
  // BUILD UI + เช็ค User Login
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 🛑 ดึงข้อมูล AuthState
    final authState = ref.watch(authControllerProvider); 
    final user = authState.user;

    // 🛑 1. ถ้าไม่ได้ Login แสดงหน้าแจ้งเตือน (ปิด Form)
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('แจ้งเหตุฉุกเฉิน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person, size: 80, color: Colors.grey),
                const SizedBox(height: 24),
                Text('กรุณาเข้าสู่ระบบ', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('กรุณาเข้าสู่ระบบก่อนทำการแจ้งเหตุ เพื่อให้เจ้าหน้าที่สามารถยืนยันตัวตน และติดต่อกลับได้', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupPhonePage()),
                      );
                    },
                    child: const Text('กลับ / เข้าสู่ระบบ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 🛑 2. ถ้า Login แล้ว โชว์ Form ปกติ
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งเหตุฉุกเฉิน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('1. สถานที่เกิดเหตุ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildMap(),
            const SizedBox(height: 24),
            Text('2. ข้อมูลเหตุการณ์และระดับความเร่งด่วน', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildCategoryGrid(),
            AnimatedSize(duration: const Duration(milliseconds: 300), child: _buildDynamicFields()),
            const SizedBox(height: 10),
            Text('3. ภาพถ่ายและรายละเอียด', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildImagePicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              validator: (val) => (val == null || val.trim().isEmpty) ? 'กรุณาระบุหัวข้อเหตุการณ์' : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'หัวข้อเหตุการณ์ *', hintText: 'เช่น ไฟไหม้บ้านไม้ / น้ำท่วมสูง',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _detailController, maxLines: 2, decoration: InputDecoration(hintText: 'รายละเอียดเพิ่มเติม...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 30),
            _buildSubmitButton(),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _buildMap() => SizedBox(height: 180, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: GoogleMap(initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 15), onMapCreated: (c) => _mapController = c, onTap: (pos) => setState(() => _selectedLocation = pos), markers: {Marker(markerId: const MarkerId('m'), position: _selectedLocation, draggable: true)})));
  Widget _buildCategoryGrid() => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: _categories.length, itemBuilder: (context, i) {
    final cat = _categories[i];
    final isSel = _selectedCategory == cat['id'];
    return InkWell(
      onTap: () => setState(() { _selectedCategory = cat['id']; _urgency = 'รอได้'; }), 
      child: Container(decoration: BoxDecoration(color: isSel ? cat['color'].withOpacity(0.1) : Colors.white, border: Border.all(color: isSel ? cat['color'] : Colors.grey.shade300, width: isSel ? 2 : 1), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(cat['icon'], color: isSel ? cat['color'] : Colors.grey), const SizedBox(height: 4), Text(cat['label'], style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center)]))
    );
  });
  Widget _buildImagePicker() => GestureDetector(onTap: () => _showImageSourceSheet(), child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: _imageFile == null ? const Icon(Icons.add_a_photo, color: Colors.grey) : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))));
  void _showImageSourceSheet() => showModalBottomSheet(context: context, builder: (c) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.camera_alt), title: const Text('ถ่ายรูป'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.camera); }), ListTile(leading: const Icon(Icons.photo_library), title: const Text('อัลบั้ม'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.gallery); })])));
  Future<void> _pickImage(ImageSource s) async { final xFile = await _picker.pickImage(source: s, imageQuality: 50); if (xFile != null) setState(() => _imageFile = File(xFile.path)); }
  Widget _buildSubmitButton() => SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _urgency == 'ถึงแก่ชีวิต' ? Colors.red : (_urgency == 'ด่วนมาก' ? Colors.orange : Colors.blueAccent), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _selectedCategory == null ? null : _submitReport, child: Text(_urgency == 'ถึงแก่ชีวิต' ? 'แจ้งเหตุด่วนถึงแก่ชีวิตทันที!' : 'ส่งแจ้งเหตุสถานการณ์', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))));

  // ==========================================
  // LOGIC ส่งข้อมูล
  // ==========================================
  void _submitReport() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนทำการแจ้งเหตุ'), backgroundColor: Colors.red));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาตรวจสอบข้อมูลช่องสีแดงให้ครบถ้วน'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      return;
    }

    Map<String, dynamic> specificData = {};
    switch (_selectedCategory) {
      case 'flood':
        specificData = {
          'has_people_waiting': _floodHasPeopleWaiting,
          'people_count': _floodHasPeopleWaiting ? (int.tryParse(_floodPeopleCountController.text) ?? 0) : 0,
          'has_electricity': _floodHasElectricity,
          'has_bedridden': _floodHasBedridden,
          'water_current': _floodWaterCurrent,
          'boat_access': _floodBoatAccess,
          'supplies_status': _floodSupplies,
          'medical_needs': {'need_meds': _floodNeedMeds, 'med_name': _floodNeedMeds ? _floodMedicationController.text.trim() : null, 'severe_disease': _floodSevereDisease, 'disease_name': _floodSevereDisease ? _floodDiseaseController.text.trim() : null}
        }; break;
      case 'fire':
        specificData = {
          'fire_type': _fireType, 'status': _fireStatus, 'has_trapped': _fireHasTrapped,
          'trapped_count': _fireHasTrapped ? (int.tryParse(_fireTrappedCountCtrl.text) ?? 0) : 0,
          'building_floors': int.tryParse(_fireFloorsCtrl.text) ?? 0, 'nearby_risk': _fireRisk, 'water_source': _fireWaterSource,
          'urgent_needs': _fireNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
        }; break;
      case 'collapse':
        specificData = {
          'feeling': _eqFeeling, 'damage': _eqDamage, 'has_trapped': _eqHasTrapped,
          'trapped_count': _eqHasTrapped ? (int.tryParse(_eqTrappedCountCtrl.text) ?? 0) : 0,
          'secondary_risk': _eqRisk, 'utilities_status': _eqUtilities.entries.where((e) => e.value == true).map((e) => e.key).toList(),
          'urgent_needs': _eqNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
        }; break;
      case 'chemical':
        specificData = {
          'characteristics': _chemChar, 'color': _chemColor, 'symptoms': _chemHasInjured ? _chemSymptom : null,
          'wind_direction': _chemWind, 'affected_area': _chemArea, 'has_injured': _chemHasInjured,
          'injured_count': _chemHasInjured ? (int.tryParse(_chemInjuredCtrl.text) ?? 0) : 0,
          'urgent_needs': _chemNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
        }; break;
      
      case 'violence':
        specificData = {
          'type': _violType, 'weapon': _violWeapon, 'suspect_status': _violStatus,
          'fled_vehicle_detail': _violStatus == 'หลบหนีไปแล้ว' ? _violFledVehicleCtrl.text.trim() : null,
          'suspect_info': _violSuspectCtrl.text.trim(), 'has_injured': _violHasInjured,
          'injured_count': _violHasInjured ? (int.tryParse(_violInjuredCtrl.text) ?? 0) : 0,
          'injury_type': _violHasInjured ? _violInjuryType : null, 'reporter_safety': _violSafety,
          'urgent_needs': _violNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
        }; break;
      case 'other':
        specificData = {
          'has_affected': _otherHasAffected,
          'affected_count': _otherHasAffected ? (int.tryParse(_otherAffectedCtrl.text) ?? 0) : 0,
          'extra_note': _detailController.text.trim(),
          'urgent_needs': _otherNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
        }; break;
    }

    try {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

      final reporterFullName = '${user.firstName} ${user.lastName}'.trim();
      final reporterName = reporterFullName.isEmpty ? 'ไม่ระบุชื่อ' : reporterFullName;

      await ref.read(incidentControllerProvider.notifier).reportIncident(
        title: _titleController.text.trim(),
        type: _selectedCategory!,
        details: specificData,
        urgency: _urgency,
        lat: _selectedLocation.latitude,
        lng: _selectedLocation.longitude,
        imageFile: _imageFile,
        userId: user.id,
        reporterName: reporterName,
        reporterTel: user.tel,
      );

      if (mounted) {
        Navigator.pop(context); 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('แจ้งเหตุสำเร็จ! เจ้าหน้าที่กำลังตรวจสอบ'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }
}