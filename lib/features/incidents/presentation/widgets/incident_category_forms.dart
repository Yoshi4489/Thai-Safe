import 'package:flutter/material.dart';
import 'incident_form_helpers.dart'; // import UI Helpers 

// ========================================================
// 1. ฟอร์มน้ำท่วม
// ========================================================
class FloodFormWidget extends StatefulWidget {
  const FloodFormWidget({super.key});
  @override
  FloodFormWidgetState createState() => FloodFormWidgetState();
}

class FloodFormWidgetState extends State<FloodFormWidget> {
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

  @override
  void dispose() {
    _floodPeopleCountController.dispose();
    _floodMedicationController.dispose();
    _floodDiseaseController.dispose();
    super.dispose();
  }

  // ฟังก์ชันส่งข้อมูลออกไปให้หน้าหลัก
  Map<String, dynamic> getFormData() {
    return {
      'has_people_waiting': _floodHasPeopleWaiting,
      'people_count': _floodHasPeopleWaiting ? (int.tryParse(_floodPeopleCountController.text) ?? 0) : 0,
      'has_electricity': _floodHasElectricity,
      'has_bedridden': _floodHasBedridden,
      'water_current': _floodWaterCurrent,
      'boat_access': _floodBoatAccess,
      'supplies_status': _floodSupplies,
      'medical_needs': {
        'need_meds': _floodNeedMeds,
        'med_name': _floodNeedMeds ? _floodMedicationController.text.trim() : null,
        'severe_disease': _floodSevereDisease,
        'disease_name': _floodSevereDisease ? _floodDiseaseController.text.trim() : null,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IncidentFormHelpers.buildSectionHeader('สภาพเหตุ และการช่วยเหลือ'),
        IncidentFormHelpers.buildSwitch('มีผู้รอรับความช่วยเหลือ หรือไม่', _floodHasPeopleWaiting, (v) => setState(() => _floodHasPeopleWaiting = v)),
        if (_floodHasPeopleWaiting)
          IncidentFormHelpers.buildNumberField('จำนวนผู้รอรับความช่วยเหลือ (ประมาณ)', _floodPeopleCountController, suffix: 'คน', validateNonZero: true),
        IncidentFormHelpers.buildSwitch('มีกระแสไฟฟ้า หรือไม่', _floodHasElectricity, (v) => setState(() => _floodHasElectricity = v)),
        IncidentFormHelpers.buildSwitch('มีผู้ป่วยติดเตียง หรือไม่', _floodHasBedridden, (v) => setState(() => _floodHasBedridden = v)),
        const SizedBox(height: 8),
        IncidentFormHelpers.buildSectionLabel('กระแสน้ำ'),
        IncidentFormHelpers.buildSegmented(['สงบ', 'ปานกลาง', 'แรงมาก'], _floodWaterCurrent, (v) => setState(() => _floodWaterCurrent = v)),
        const SizedBox(height: 12),
        IncidentFormHelpers.buildSectionLabel('เรือสามารถเข้าไปได้ หรือไม่'),
        IncidentFormHelpers.buildSegmented(['ไม่ได้', 'ไม่แน่ใจ', 'ได้'], _floodBoatAccess, (v) => setState(() => _floodBoatAccess = v)),
        const SizedBox(height: 12),
        IncidentFormHelpers.buildSectionLabel('อาหาร และน้ำมีเพียงพอ หรือไม่'),
        IncidentFormHelpers.buildSegmented(['ไม่มีเลย', 'พอมี', 'เพียงพอ'], _floodSupplies, (v) => setState(() => _floodSupplies = v)),
        const Divider(height: 24),
        IncidentFormHelpers.buildSectionLabel('ข้อมูลทางการแพทย์เพิ่มเติม'),
        IncidentFormHelpers.buildSwitch('มีผู้ต้องการยาประจำตัว หรือไม่', _floodNeedMeds, (v) => setState(() => _floodNeedMeds = v)),
        if (_floodNeedMeds) IncidentFormHelpers.buildTextField('โปรดระบุชื่อยา...', _floodMedicationController),
        IncidentFormHelpers.buildSwitch('มีผู้ที่มีโรคประจำตัวรุนแรง หรือไม่', _floodSevereDisease, (v) => setState(() => _floodSevereDisease = v)),
        if (_floodSevereDisease) IncidentFormHelpers.buildTextField('โปรดระบุชื่อโรค...', _floodDiseaseController),
      ],
    );
  }
}

// ========================================================
// 2. ฟอร์มไฟไหม้
// ========================================================
class FireFormWidget extends StatefulWidget {
  const FireFormWidget({super.key});
  @override
  FireFormWidgetState createState() => FireFormWidgetState();
}

class FireFormWidgetState extends State<FireFormWidget> {
  String _fireType = 'บ้าน/อาคาร';
  String _fireStatus = 'ควันเล็กน้อย';
  bool _fireHasTrapped = false;
  final TextEditingController _fireTrappedCountCtrl = TextEditingController();
  final TextEditingController _fireFloorsCtrl = TextEditingController();
  String _fireRisk = 'ไม่มี';
  String _fireWaterSource = 'ไม่มี';
  final Map<String, bool> _fireNeeds = {'ถังดับเพลิง': false, 'รถดับเพลิง': false, 'รถพยาบาล': false, 'กู้ภัยที่สูง (รถกระเช้า)': false};

  @override
  void dispose() {
    _fireTrappedCountCtrl.dispose();
    _fireFloorsCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> getFormData() {
    return {
      'fire_type': _fireType, 'status': _fireStatus, 'has_trapped': _fireHasTrapped,
      'trapped_count': _fireHasTrapped ? (int.tryParse(_fireTrappedCountCtrl.text) ?? 0) : 0,
      'building_floors': int.tryParse(_fireFloorsCtrl.text) ?? 0, 'nearby_risk': _fireRisk, 'water_source': _fireWaterSource,
      'urgent_needs': _fireNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IncidentFormHelpers.buildSectionHeader('ข้อมูลการเพลิงไหม้'),
        IncidentFormHelpers.buildDropdown('ประเภทของไฟ', ['บ้าน/อาคาร', 'โรงงาน/สารเคมี', 'หญ้า/ป่า', 'ยานพาหนะ'], _fireType, (v) => setState(() => _fireType = v!)),
        IncidentFormHelpers.buildSectionLabel('สถานะปัจจุบัน'),
        IncidentFormHelpers.buildSegmented(['ควันเล็กน้อย', 'ไฟลามหนัก', 'คุมเพลิงได้'], _fireStatus, (v) => setState(() => _fireStatus = v)),
        IncidentFormHelpers.buildSwitch('มีคนติดอยู่ในพื้นที่ หรือไม่', _fireHasTrapped, (v) => setState(() => _fireHasTrapped = v)),
        if (_fireHasTrapped) IncidentFormHelpers.buildNumberField('จำนวนผู้ติดอยู่ (คน)', _fireTrappedCountCtrl, validateNonZero: true),
        if (_fireType == 'บ้าน/อาคาร' || _fireType == 'โรงงาน/สารเคมี') IncidentFormHelpers.buildNumberField('ความสูงของอาคาร (ชั้น)', _fireFloorsCtrl),
        IncidentFormHelpers.buildDropdown('จุดเสี่ยงใกล้เคียง', ['ไม่มี', 'ปั๊มน้ำมัน', 'แหล่งสารเคมี', 'เสาไฟฟ้าแรงสูง'], _fireRisk, (v) => setState(() => _fireRisk = v!)),
        IncidentFormHelpers.buildSectionLabel('แหล่งน้ำใกล้เคียง'),
        IncidentFormHelpers.buildSegmented(['มีประปา/หัวแดง', 'มีคลอง', 'ไม่มี'], _fireWaterSource, (v) => setState(() => _fireWaterSource = v)),
        const Divider(height: 24),
        IncidentFormHelpers.buildSectionLabel('ความต้องการเร่งด่วน'),
        ..._fireNeeds.keys.map((key) => IncidentFormHelpers.buildCheckbox(key, _fireNeeds[key]!, (v) => setState(() => _fireNeeds[key] = v ?? false))),
      ],
    );
  }
}

// ========================================================
// 3. ฟอร์มแผ่นดินไหว/อาคารถล่ม
// ========================================================
class CollapseFormWidget extends StatefulWidget {
  const CollapseFormWidget({super.key});
  @override
  CollapseFormWidgetState createState() => CollapseFormWidgetState();
}

class CollapseFormWidgetState extends State<CollapseFormWidget> {
  String _eqFeeling = 'สั่นสะเทือนเล็กน้อย';
  String _eqDamage = 'ไม่มี';
  bool _eqHasTrapped = false;
  final TextEditingController _eqTrappedCountCtrl = TextEditingController();
  String _eqRisk = 'ไม่มีความเสี่ยงต่อเนื่อง';
  final Map<String, bool> _eqUtilities = {'ไฟฟ้าดับ': false, 'ท่อประปาแตก': false, 'แก๊สรั่ว': false};
  final Map<String, bool> _eqNeeds = {'ทีมค้นหา (K9/USAR)': false, 'หน่วยแพทย์': false, 'อาหาร/ที่พักชั่วคราว': false};

  @override
  void dispose() {
    _eqTrappedCountCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> getFormData() {
    return {
      'feeling': _eqFeeling, 'damage': _eqDamage, 'has_trapped': _eqHasTrapped,
      'trapped_count': _eqHasTrapped ? (int.tryParse(_eqTrappedCountCtrl.text) ?? 0) : 0,
      'secondary_risk': _eqRisk,
      'utilities_status': _eqUtilities.entries.where((e) => e.value == true).map((e) => e.key).toList(),
      'urgent_needs': _eqNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IncidentFormHelpers.buildSectionHeader('สถานการณ์แผ่นดินไหว/อาคารถล่ม'),
        IncidentFormHelpers.buildDropdown('ความรู้สึกขณะเกิด', ['ไม่รู้สึก', 'สั่นสะเทือนเล็กน้อย', 'ข้าวของตกหล่น', 'ทรงตัวลำบาก'], _eqFeeling, (v) => setState(() => _eqFeeling = v!)),
        IncidentFormHelpers.buildDropdown('ความเสียหายของอาคาร', ['ไม่มี', 'ผนังร้าวเล็กน้อย', 'โครงสร้างทรุด/พัง', 'ถล่มทั้งหมด'], _eqDamage, (v) => setState(() => _eqDamage = v!)),
        IncidentFormHelpers.buildSwitch('มีคนติดใต้ซากอาคาร หรือไม่', _eqHasTrapped, (v) => setState(() => _eqHasTrapped = v)),
        if (_eqHasTrapped) IncidentFormHelpers.buildNumberField('จำนวนผู้ติดอยู่ (คน)', _eqTrappedCountCtrl, validateNonZero: true),
        IncidentFormHelpers.buildDropdown('ความเสี่ยงต่อเนื่อง', ['ไม่มีความเสี่ยงต่อเนื่อง', 'ได้ยินเสียงอาคารลั่น', 'อยู่ใกล้หน้าผา/ดินสไลด์', 'อยู่ใกล้ชายฝั่ง (เสี่ยงสึนามิ)'], _eqRisk, (v) => setState(() => _eqRisk = v!)),
        const Divider(height: 24),
        IncidentFormHelpers.buildSectionLabel('สถานะสาธารณูปโภค'),
        ..._eqUtilities.keys.map((key) => IncidentFormHelpers.buildCheckbox(key, _eqUtilities[key]!, (v) => setState(() => _eqUtilities[key] = v ?? false))),
        const Divider(height: 24),
        IncidentFormHelpers.buildSectionLabel('ความต้องการเร่งด่วน'),
        ..._eqNeeds.keys.map((key) => IncidentFormHelpers.buildCheckbox(key, _eqNeeds[key]!, (v) => setState(() => _eqNeeds[key] = v ?? false))),
      ],
    );
  }
}

// ========================================================
// 4. ฟอร์มสารเคมีรั่วไหล
// ========================================================
class ChemicalFormWidget extends StatefulWidget {
  const ChemicalFormWidget({super.key});
  @override
  ChemicalFormWidgetState createState() => ChemicalFormWidgetState();
}

class ChemicalFormWidgetState extends State<ChemicalFormWidget> {
  String _chemChar = 'กลิ่นฉุนรุนแรง'; String _chemColor = 'ใส/ไม่มีสี'; String _chemSymptom = 'แสบตา/ผิวหนัง';
  String _chemWind = 'ลมสงบ'; String _chemArea = 'ภายในอาคาร'; bool _chemHasInjured = false;
  final TextEditingController _chemInjuredCtrl = TextEditingController();
  final Map<String, bool> _chemNeeds = {'ชุด PPE/กู้ภัยสารเคมี': false, 'รถพยาบาล': false, 'ประกาศอพยพ': false};

  @override
  void dispose() { _chemInjuredCtrl.dispose(); super.dispose(); }

  Map<String, dynamic> getFormData() {
    return {
      'characteristics': _chemChar, 'color': _chemColor, 'symptoms': _chemHasInjured ? _chemSymptom : null,
      'wind_direction': _chemWind, 'affected_area': _chemArea, 'has_injured': _chemHasInjured,
      'injured_count': _chemHasInjured ? (int.tryParse(_chemInjuredCtrl.text) ?? 0) : 0,
      'urgent_needs': _chemNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IncidentFormHelpers.buildSectionHeader('ข้อมูลสารเคมีรั่วไหล'),
        IncidentFormHelpers.buildDropdown('ลักษณะสิ่งที่พบ', ['กลุ่มควัน', 'กลิ่นฉุนรุนแรง', 'ของเหลวรั่วไหล', 'มีเสียงระเบิด'], _chemChar, (v) => setState(() => _chemChar = v!)),
        IncidentFormHelpers.buildSectionLabel('สีของควัน/สารเคมี'),
        IncidentFormHelpers.buildSegmented(['ใส/ไม่มีสี', 'ขาว', 'เหลือง/ส้ม', 'ดำ'], _chemColor, (v) => setState(() => _chemColor = v)),
        IncidentFormHelpers.buildSectionLabel('ทิศทางลม'),
        IncidentFormHelpers.buildSegmented(['ลมสงบ', 'พัดเข้าชุมชน', 'พัดออกชุมชน'], _chemWind, (v) => setState(() => _chemWind = v)),
        IncidentFormHelpers.buildSectionLabel('พื้นที่ได้รับผลกระทบ'),
        IncidentFormHelpers.buildSegmented(['ภายในอาคาร', 'รัศมี 500ม.', 'รัศมีเกิน 1กม.'], _chemArea, (v) => setState(() => _chemArea = v)),
        const Divider(height: 12),
        IncidentFormHelpers.buildSwitch('มีผู้ได้รับบาดเจ็บ หรือไม่', _chemHasInjured, (v) => setState(() => _chemHasInjured = v)),
        if (_chemHasInjured) ...[
          IncidentFormHelpers.buildNumberField('จำนวนผู้ได้รับบาดเจ็บ (คน)', _chemInjuredCtrl, validateNonZero: true),
          IncidentFormHelpers.buildDropdown('อาการของผู้บาดเจ็บ', ['แสบตา/ผิวหนัง', 'หายใจไม่ออก', 'หมดสติ', 'อาเจียน'], _chemSymptom, (v) => setState(() => _chemSymptom = v!)),
        ],
        const Divider(height: 24),
        IncidentFormHelpers.buildSectionLabel('ความต้องการเร่งด่วน'),
        ..._chemNeeds.keys.map((key) => IncidentFormHelpers.buildCheckbox(key, _chemNeeds[key]!, (v) => setState(() => _chemNeeds[key] = v ?? false))),
      ],
    );
  }
}

// ========================================================
// 5. ฟอร์มเหตุร้าย/อาชญากรรม
// ========================================================
class ViolenceFormWidget extends StatefulWidget {
  const ViolenceFormWidget({super.key});
  @override
  ViolenceFormWidgetState createState() => ViolenceFormWidgetState();
}

class ViolenceFormWidgetState extends State<ViolenceFormWidget> {
  String _violType = 'ทะเลาะวิวาท'; String _violWeapon = 'ไม่มี/ไม่เห็น'; String _violStatus = 'ยังอยู่ในพื้นที่';
  final TextEditingController _violFledVehicleCtrl = TextEditingController();
  bool _violHasInjured = false; final TextEditingController _violInjuredCtrl = TextEditingController();
  String _violInjuryType = 'บาดเจ็บเล็กน้อย'; String _violSafety = 'กำลังซ่อนตัว';
  final TextEditingController _violSuspectCtrl = TextEditingController();
  final Map<String, bool> _violNeeds = {'ตำรวจ': false, 'รถพยาบาล': false, 'หน่วยกู้ภัย': false};

  @override
  void dispose() { _violFledVehicleCtrl.dispose(); _violInjuredCtrl.dispose(); _violSuspectCtrl.dispose(); super.dispose(); }

  Map<String, dynamic> getFormData() {
    return {
      'type': _violType, 'weapon': _violWeapon, 'suspect_status': _violStatus,
      'fled_vehicle_detail': _violStatus == 'หลบหนีไปแล้ว' ? _violFledVehicleCtrl.text.trim() : null,
      'suspect_info': _violSuspectCtrl.text.trim(), 'has_injured': _violHasInjured,
      'injured_count': _violHasInjured ? (int.tryParse(_violInjuredCtrl.text) ?? 0) : 0,
      'injury_type': _violHasInjured ? _violInjuryType : null, 'reporter_safety': _violSafety,
      'urgent_needs': _violNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IncidentFormHelpers.buildSectionHeader('สถานการณ์เหตุร้าย/อาชญากรรม'),
        IncidentFormHelpers.buildDropdown('ประเภทเหตุ', ['ทำร้ายร่างกาย', 'วิ่งราว/ชิงทรัพย์', 'ทะเลาะวิวาท', 'กราดยิง/จับตัวประกัน'], _violType, (v) => setState(() => _violType = v!)),
        IncidentFormHelpers.buildDropdown('อาวุธที่พบ', ['ไม่มี/ไม่เห็น', 'มีด/ของมีคม', 'ปืน', 'ระเบิด'], _violWeapon, (v) => setState(() => _violWeapon = v!)),
        IncidentFormHelpers.buildDropdown('สถานะผู้ก่อเหตุ', ['ยังอยู่ในพื้นที่', 'หลบหนีไปแล้ว', 'ไม่ทราบ'], _violStatus, (v) => setState(() => _violStatus = v!)),
        if (_violStatus == 'หลบหนีไปแล้ว') IncidentFormHelpers.buildTextField('พาหนะที่ใช้หลบหนี / ป้ายทะเบียน', _violFledVehicleCtrl, hint: 'เช่น มอเตอร์ไซค์สีแดง...'),
        IncidentFormHelpers.buildTextField('รูปพรรณสันฐานผู้ก่อเหตุ', _violSuspectCtrl, hint: 'เสื้อผ้าหน้าผม...'),
        const Divider(height: 12),
        IncidentFormHelpers.buildSwitch('มีผู้ได้รับบาดเจ็บ หรือไม่', _violHasInjured, (v) => setState(() => _violHasInjured = v)),
        if (_violHasInjured) ...[
          IncidentFormHelpers.buildNumberField('จำนวนผู้บาดเจ็บ (คน)', _violInjuredCtrl, validateNonZero: true),
          IncidentFormHelpers.buildDropdown('อาการบาดเจ็บหลัก', ['แผลถูกฟัน/ยิง', 'หมดสติ', 'บาดเจ็บเล็กน้อย'], _violInjuryType, (v) => setState(() => _violInjuryType = v!)),
        ],
        const Divider(height: 12),
        IncidentFormHelpers.buildSectionLabel('ความปลอดภัยของคุณ'),
        IncidentFormHelpers.buildSegmented(['ปลอดภัยแล้ว', 'กำลังซ่อนตัว', 'กำลังเผชิญหน้า'], _violSafety, (v) => setState(() => _violSafety = v)),
        const Divider(height: 24),
        IncidentFormHelpers.buildSectionLabel('ความต้องการเร่งด่วน'),
        ..._violNeeds.keys.map((key) => IncidentFormHelpers.buildCheckbox(key, _violNeeds[key]!, (v) => setState(() => _violNeeds[key] = v ?? false))),
      ],
    );
  }
}

// ========================================================
// 6. ฟอร์มเหตุอื่นๆ
// ========================================================
class OtherFormWidget extends StatefulWidget {
  const OtherFormWidget({super.key});
  @override
  OtherFormWidgetState createState() => OtherFormWidgetState();
}

class OtherFormWidgetState extends State<OtherFormWidget> {
  bool _otherHasAffected = false;
  final TextEditingController _otherAffectedCtrl = TextEditingController();
  final Map<String, bool> _otherNeeds = {'แพทย์/รถพยาบาล': false, 'ตำรวจ': false, 'กู้ภัยทางถนน': false, 'กู้ภัยทั่วไป': false};

  @override
  void dispose() { _otherAffectedCtrl.dispose(); super.dispose(); }

  Map<String, dynamic> getFormData() {
    return {
      'has_affected': _otherHasAffected,
      'affected_count': _otherHasAffected ? (int.tryParse(_otherAffectedCtrl.text) ?? 0) : 0,
      'urgent_needs': _otherNeeds.entries.where((e) => e.value == true).map((e) => e.key).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IncidentFormHelpers.buildSectionHeader('เหตุฉุกเฉินอื่นๆ'),
        IncidentFormHelpers.buildSwitch('มีผู้ได้รับผลกระทบ หรือไม่', _otherHasAffected, (v) => setState(() => _otherHasAffected = v)),
        if (_otherHasAffected) IncidentFormHelpers.buildNumberField('จำนวนผู้ได้รับผลกระทบ (คน)', _otherAffectedCtrl, validateNonZero: true),
        const Divider(height: 24),
        IncidentFormHelpers.buildSectionLabel('ความต้องการเร่งด่วน'),
        ..._otherNeeds.keys.map((key) => IncidentFormHelpers.buildCheckbox(key, _otherNeeds[key]!, (v) => setState(() => _otherNeeds[key] = v ?? false))),
      ],
    );
  }
}