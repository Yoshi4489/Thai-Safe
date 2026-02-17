import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
  String? _selectedCategory;
  File? _imageFile;
  
  // --- Controllers หลัก ---
  final TextEditingController _titleController = TextEditingController(); 
  final TextEditingController _detailController = TextEditingController();
  
  // --- Controllers & Variables เฉพาะเหตุน้ำท่วม (เพื่อเตรียมส่ง Firebase) ---
  final TextEditingController _floodPeopleCountController = TextEditingController();
  final TextEditingController _floodMedicationController = TextEditingController();
  final TextEditingController _floodDiseaseController = TextEditingController();
  
  bool _floodHasElectricity = false;
  bool _floodHasBedridden = false;
  bool _floodNeedMeds = false;
  bool _floodSevereDisease = false;
  
  String _floodWaterCurrent = 'สงบ'; // สงบ, ปานกลาง, แรงมาก
  String _floodBoatAccess = 'ไม่ได้'; // ไม่ได้, ไม่แน่ใจ, ได้
  String _floodSupplies = 'ไม่มีเลย'; // ไม่มีเลย, พอมี, เพียงพอ

  final ImagePicker _picker = ImagePicker();
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;

  // ตัวแปรสำหรับเหตุการณ์อื่น
  bool _boolParam1 = false; 
  bool _boolParam2 = false; 
  String _envStatus = ''; 

  // ตัวแปรความเร่งด่วน
  String _urgency = 'รอได้';

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
    _getCurrentLocation();
  }

  // --- เพิ่ม Dispose เพื่อคืน Memory ---
  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _floodPeopleCountController.dispose();
    _floodMedicationController.dispose();
    _floodDiseaseController.dispose();
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

  // --- ส่วนเลือกความเร่งด่วน (Updated ตาม Requirement) ---
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
              // กำหนดสีตามระดับความรุนแรง
              Color color;
              if (level == 'ถึงแก่ชีวิต') color = Colors.red;
              else if (level == 'ด่วนมาก') color = Colors.orange;
              else color = Colors.green;

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

  Widget _buildDynamicFields() {
    if (_selectedCategory == null) return const SizedBox.shrink();

    List<Widget> children = [];

    switch (_selectedCategory) {

      // CASE: FLOOD (ปรับปรุงใหม่ตาม Requirement)

      case 'flood':
        children.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('สภาพเหตุ และการช่วยเหลือ'),
            
            // 1. จำนวนผู้รอรับความช่วยเหลือ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _floodPeopleCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // รับเฉพาะตัวเลข
                decoration: InputDecoration(
                  labelText: 'จำนวนผู้รอรับความช่วยเหลือ (ประมาณ)',
                  suffixText: 'คน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.people_outline),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),

            // 2. Switches พื้นฐาน
            _buildSwitch('มีกระแสไฟฟ้า หรือไม่', _floodHasElectricity, (v) => setState(() => _floodHasElectricity = v)),
            _buildSwitch('มีผู้ป่วยติดเตียง หรือไม่', _floodHasBedridden, (v) => setState(() => _floodHasBedridden = v)),

            const SizedBox(height: 8),

            // 3. กระแสน้ำ
            _sectionLabel('กระแสน้ำ'),
            _buildSegmented(['สงบ', 'ปานกลาง', 'แรงมาก'], _floodWaterCurrent, (v) => setState(() => _floodWaterCurrent = v)),
            
            const SizedBox(height: 12),

            // 4. เรือเข้าได้หรือไม่
            _sectionLabel('เรือสามารถเข้าไปได้ หรือไม่'),
            _buildSegmented(['ไม่ได้', 'ไม่แน่ใจ', 'ได้'], _floodBoatAccess, (v) => setState(() => _floodBoatAccess = v)),

             const SizedBox(height: 12),

            // 5. อาหารและน้ำ
            _sectionLabel('อาหาร และน้ำมีเพียงพอ หรือไม่'),
            _buildSegmented(['ไม่มีเลย', 'พอมี', 'เพียงพอ'], _floodSupplies, (v) => setState(() => _floodSupplies = v)),

            const Divider(height: 24),
            _sectionLabel('ข้อมูลทางการแพทย์เพิ่มเติม'),

            // 6. ต้องการยาประจำตัว
            _buildSwitch('มีผู้ต้องการยาประจำตัว หรือไม่', _floodNeedMeds, (v) => setState(() => _floodNeedMeds = v)),
            if (_floodNeedMeds) // Show only if true
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: TextField(
                  controller: _floodMedicationController,
                  decoration: const InputDecoration(
                    hintText: 'โปรดระบุชื่อยา...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),

            // 7. โรคประจำตัวรุนแรง
            _buildSwitch('มีผู้ที่มีโรคประจำตัวรุนแรง หรือไม่', _floodSevereDisease, (v) => setState(() => _floodSevereDisease = v)),
            if (_floodSevereDisease) // Show only if true
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: TextField(
                  controller: _floodDiseaseController,
                  decoration: const InputDecoration(
                    hintText: 'โปรดระบุชื่อโรค...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
          ],
        ));
        break;


      // CASE: OTHERS

      case 'fire':
        children.add(Column(children: [
          _sectionHeader('การลุกลามและควัน'),
          _buildSwitch('ไฟกำลังลามไปอาคารข้างเคียง', _boolParam1, (v) => setState(() => _boolParam1 = v)),
          _buildSwitch('มีเสียงระเบิดเป็นระยะ', _boolParam2, (v) => setState(() => _boolParam2 = v)),
          _sectionLabel('ลักษณะกลุ่มควัน'),
          _buildSegmented(['ควันขาว', 'ควันดำจัด', 'กลิ่นเคมี'], _envStatus, (v) => setState(() => _envStatus = v)),
        ]));
        break;
      case 'violence':
        children.add(Column(children: [
          _sectionHeader('ความปลอดภัยพื้นที่'),
          _buildSwitch('ผู้ก่อเหตุยังอยู่ในที่เกิดเหตุ', _boolParam1, (v) => setState(() => _boolParam1 = v)),
          _buildSwitch('มีการใช้อาวุธ (ปืน/มีด/อื่นๆ)', _boolParam1, (v) => setState(() => _boolParam1 = v)), 
          _sectionLabel('ความวุ่นวาย'),
          _buildSegmented(['เบาบาง', 'วุ่นวาย', 'คุมไม่ได้'], _envStatus, (v) => setState(() => _envStatus = v)),
        ]));
        break;
      default:
        children.add(_sectionHeader('ข้อมูลสถานการณ์เพิ่มเติม'));
    }

    // ทุกเหตุการณ์ต้องระบุความเร่งด่วนต่อท้ายเสมอ
    children.add(_buildUrgencyPicker());

    // ปรับสี Background ตามความเร่งด่วน
    Color bgAlertColor;
    if (_urgency == 'ถึงแก่ชีวิต') bgAlertColor = Colors.red.withOpacity(0.1);
    else if (_urgency == 'ด่วนมาก') bgAlertColor = Colors.orange.withOpacity(0.1);
    else bgAlertColor = Colors.blue.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgAlertColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _urgency == 'ถึงแก่ชีวิต' ? Colors.red : (_urgency == 'ด่วนมาก' ? Colors.orange : Colors.blue.shade200), 
          width: 1.5
        ),
      ),
      child: Column(children: children),
    );
  }

  // --- Helpers ---
  Widget _sectionHeader(String title) => ListTile(
    leading: const Icon(Icons.analytics_outlined, color: Colors.redAccent),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
  );
  
  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
    child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
  );
  
  Widget _buildSwitch(String title, bool val, Function(bool) onChanged) => SwitchListTile(
    title: Text(title, style: const TextStyle(fontSize: 14)), 
    value: val, 
    onChanged: onChanged, 
    activeColor: Colors.redAccent,
    dense: true, // ทำให้ Compact ขึ้น
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
  
  Widget _buildSegmented(List<String> opts, String selected, Function(String) onSelect) {
    // ป้องกันกรณีค่า selected เดิมไม่ตรงกับ List ใหม่
    final currentSelection = opts.contains(selected) ? selected : opts.first;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      child: SizedBox(
        width: double.infinity, 
        child: SegmentedButton<String>(
          segments: opts.map((o) => ButtonSegment(value: o, label: Text(o, style: const TextStyle(fontSize: 12)))).toList(), 
          selected: {currentSelection}, 
          onSelectionChanged: (v) => onSelect(v.first),
          style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งเหตุฉุกเฉิน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
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
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'หัวข้อเหตุการณ์',
              hintText: 'เช่น ไฟไหม้บ้านไม้ / น้ำท่วมสูง',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          
          const SizedBox(height: 16),
          TextField(
            controller: _detailController, 
            maxLines: 2, 
            decoration: InputDecoration(
              hintText: 'รายละเอียดเพิ่มเติม...', 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
            )
          ),
          const SizedBox(height: 30),
          _buildSubmitButton(),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildMap() => SizedBox(height: 180, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: GoogleMap(initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 15), onMapCreated: (c) => _mapController = c, onTap: (pos) => setState(() => _selectedLocation = pos), markers: {Marker(markerId: const MarkerId('m'), position: _selectedLocation, draggable: true)})));

  Widget _buildCategoryGrid() => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: _categories.length, itemBuilder: (context, i) {
    final cat = _categories[i];
    final isSel = _selectedCategory == cat['id'];
    return InkWell(
      onTap: () => setState(() { 
        _selectedCategory = cat['id']; 
        // Reset ค่า Generic เดิม
        _boolParam1 = false; 
        _boolParam2 = false; 
        _envStatus = ''; 
        _urgency = 'รอได้'; 
        // Note: ค่าของ Flood ไม่ต้อง Reset ตรงนี้ก็ได้ หรือจะ Reset ก็ได้ถ้าต้องการ
      }), 
      child: Container(
        decoration: BoxDecoration(color: isSel ? cat['color'].withOpacity(0.1) : Colors.white, border: Border.all(color: isSel ? cat['color'] : Colors.grey.shade300, width: isSel ? 2 : 1), borderRadius: BorderRadius.circular(12)), 
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(cat['icon'], color: isSel ? cat['color'] : Colors.grey), const SizedBox(height: 4), Text(cat['label'], style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center)])
      )
    );
  });

  Widget _buildImagePicker() => GestureDetector(onTap: () => _showImageSourceSheet(), child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: _imageFile == null ? const Icon(Icons.add_a_photo, color: Colors.grey) : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))));

  void _showImageSourceSheet() => showModalBottomSheet(context: context, builder: (c) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.camera_alt), title: const Text('ถ่ายรูป'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.camera); }), ListTile(leading: const Icon(Icons.photo_library), title: const Text('อัลบั้ม'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.gallery); })])));

  Future<void> _pickImage(ImageSource s) async { final xFile = await _picker.pickImage(source: s, imageQuality: 50); if (xFile != null) setState(() => _imageFile = File(xFile.path)); }

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity, 
    height: 56, 
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _urgency == 'ถึงแก่ชีวิต' ? Colors.red : (_urgency == 'ด่วนมาก' ? Colors.orange : Colors.blueAccent), 
        foregroundColor: Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ), 
      onPressed: _selectedCategory == null ? null : _submitReport, 
      child: Text(_urgency == 'ถึงแก่ชีวิต' ? 'แจ้งเหตุด่วนถึงแก่ชีวิตทันที!' : 'ส่งแจ้งเหตุสถานการณ์', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
    )
  );

  void _submitReport() {
    // -------------------------------------------------------------
    // DATA PREPARATION (Database <=> Service)
    // -------------------------------------------------------------
    
    // 1. สร้าง Base Data (ข้อมูลพื้นฐาน)
    final baseData = {
      'category': _selectedCategory,
      'title': _titleController.text.trim(),
      'description': _detailController.text.trim(),
      'urgency': _urgency, // รอได้, ด่วนมาก, ถึงแก่ชีวิต
      'location': {
        'lat': _selectedLocation.latitude,
        'lng': _selectedLocation.longitude,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 2. สร้าง Specific Data ตามประเภท
    Map<String, dynamic> specificData = {};
    
    if (_selectedCategory == 'flood') {
      specificData = {
        'people_count': int.tryParse(_floodPeopleCountController.text) ?? 0,
        'has_electricity': _floodHasElectricity,
        'has_bedridden': _floodHasBedridden,
        'water_current': _floodWaterCurrent, // สงบ, ปานกลาง, แรงมาก
        'boat_access': _floodBoatAccess, // ไม่ได้, ไม่แน่ใจ, ได้
        'supplies_status': _floodSupplies, // ไม่มีเลย, พอมี, เพียงพอ
        'medical_needs': {
          'need_meds': _floodNeedMeds,
          'med_name': _floodNeedMeds ? _floodMedicationController.text.trim() : null,
          'severe_disease': _floodSevereDisease,
          'disease_name': _floodSevereDisease ? _floodDiseaseController.text.trim() : null,
        }
      };
    } else {
      // กรณีเหตุอื่น ๆ (ใช้ Generic เก่า)
      specificData = {
        'param1': _boolParam1,
        'param2': _boolParam2,
        'env_status': _envStatus,
      };
    }

    // 3. รวมร่างข้อมูล (Payload) เตรียมส่ง Provider
    final finalPayload = {
      ...baseData,
      'details': specificData,
    };

    print('----- SENDING REPORT TO SERVICE -----');
    print(finalPayload);
    
    // เรียก Service/Provider ตรงนี้ เช่น ref.read(incidentProvider.notifier).createReport(finalPayload, _imageFile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _urgency == 'ถึงแก่ชีวิต' ? Colors.red : Colors.green, 
        content: Text('ส่งข้อมูลเรียบร้อย (ดู Log เพื่อตรวจสอบ Data Structure)')
      )
    );
    Navigator.pop(context);
  }
}