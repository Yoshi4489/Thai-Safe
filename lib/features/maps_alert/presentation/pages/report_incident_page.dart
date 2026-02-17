import 'dart:io';
import 'package:flutter/material.dart';
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
  
  // --- 1. เพิ่มตัวแปร Controller สำหรับหัวข้อ ---
  final TextEditingController _titleController = TextEditingController(); 
  final TextEditingController _detailController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;

  // ตัวแปรสภาพแวดล้อมเฉพาะเหตุ
  bool _boolParam1 = false; 
  bool _boolParam2 = false; 
  bool _boolParam3 = false;
  String _envStatus = ''; 

  // ตัวแปรความเร่งด่วน (ต้องมีทุกเหตุการณ์)
  String _urgency = 'ปกติ';

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
    _getCurrentLocation();
  }

  // (ส่วน Dispose ควรมีเพื่อคืน Memory Controller แต่ตามคำสั่งไม่แก้ส่วนอื่น จึงละไว้ตามเดิม)

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

  // --- ส่วนเลือกความเร่งด่วน (ใช้ร่วมกันทุกเหตุ) ---
  Widget _buildUrgencyPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        _sectionHeader('ความเร่งด่วน (Triage)'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['ปกติ', 'เร่งด่วน', 'ถึงแก่ชีวิต'].map((level) {
              bool isSelected = _urgency == level;
              Color color = level == 'ถึงแก่ชีวิต' ? Colors.red : (level == 'ด่วน' ? Colors.orange : Colors.blue);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(child: Text(level)),
                    selected: isSelected,
                    selectedColor: color.withOpacity(0.2),
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

    // เพิ่มฟิลด์ตามประเภทเหตุ
    switch (_selectedCategory) {
      case 'flood':
        children.add(Column(children: [
          _sectionHeader('สภาพน้ำและการเข้าถึง'),
          _buildSwitch('กระแสน้ำไหลเชี่ยว', _boolParam1, (v) => setState(() => _boolParam1 = v)),
          _buildSwitch('มีกระแสไฟฟ้า', _boolParam2, (v) => setState(() => _boolParam2 = v)),
          _buildSwitch('มีผู้ป่วยติดเตียง หรือไม่', _boolParam3, (v) => setState(() => _boolParam3 = v)),
          _sectionLabel('ยานพาหนะเข้าถึงได้ หรือไม่?'),
          _buildSegmented(['ไม่ได้', 'รถยกสูง', 'เริอ', 'ได้ทุกชนิด'], _envStatus, (v) => setState(() => _envStatus = v)),
        ]));
        break;
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
          _buildSwitch('มีการใช้อาวุธ (ปืน/มีด/อื่นๆ)', _boolParam2, (v) => setState(() => _boolParam2 = v)),
          _sectionLabel('ความวุ่นวาย'),
          _buildSegmented(['เบาบาง', 'วุ่นวาย', 'คุมไม่ได้'], _envStatus, (v) => setState(() => _envStatus = v)),
        ]));
        break;
      default:
        children.add(_sectionHeader('ข้อมูลสถานการณ์เพิ่มเติม'));
    }

    // ทุกเหตุการณ์ต้องระบุความเร่งด่วนต่อท้ายเสมอ
    children.add(_buildUrgencyPicker());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _urgency == 'วิกฤต' ? Colors.red.withOpacity(0.08) : Colors.red.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _urgency == 'วิกฤต' ? Colors.red : Colors.red.shade100, width: 1.5),
      ),
      child: Column(children: children),
    );
  }

  // --- Helpers ---
  Widget _sectionHeader(String title) => ListTile(
    leading: const Icon(Icons.analytics_outlined, color: Colors.redAccent),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
  );
  Widget _sectionLabel(String label) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));
  Widget _buildSwitch(String title, bool val, Function(bool) onChanged) => SwitchListTile(title: Text(title, style: const TextStyle(fontSize: 14)), value: val, onChanged: onChanged, activeColor: Colors.redAccent);
  Widget _buildSegmented(List<String> opts, String selected, Function(String) onSelect) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: double.infinity, child: SegmentedButton<String>(segments: opts.map((o) => ButtonSegment(value: o, label: Text(o, style: const TextStyle(fontSize: 11)))).toList(), selected: {selected.isEmpty ? opts.first : selected}, onSelectionChanged: (v) => onSelect(v.first))));

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
          
          // --- 2. ส่วนที่เพิ่ม: ช่องกรอกหัวข้อเหตุการณ์ (ใต้รูป เหนือรายละเอียด) ---
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'หัวข้อเหตุการณ์',
              hintText: 'เช่น ไฟไหม้บ้านไม้ 2 ชั้น / น้ำท่วมสูง',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          // -------------------------------------------------------------
          
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
    return InkWell(onTap: () => setState(() { _selectedCategory = cat['id']; _boolParam1 = false; _boolParam2 = false; _envStatus = ''; _urgency = 'ปกติ'; }), child: Container(decoration: BoxDecoration(color: isSel ? cat['color'].withOpacity(0.1) : Colors.white, border: Border.all(color: isSel ? cat['color'] : Colors.grey.shade300, width: isSel ? 2 : 1), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(cat['icon'], color: isSel ? cat['color'] : Colors.grey), const SizedBox(height: 4), Text(cat['label'], style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center)])));
  });

  Widget _buildImagePicker() => GestureDetector(onTap: () => _showImageSourceSheet(), child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: _imageFile == null ? const Icon(Icons.add_a_photo, color: Colors.grey) : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))));

  void _showImageSourceSheet() => showModalBottomSheet(context: context, builder: (c) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.camera_alt), title: const Text('ถ่ายรูป'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.camera); }), ListTile(leading: const Icon(Icons.photo_library), title: const Text('อัลบั้ม'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.gallery); })])));

  Future<void> _pickImage(ImageSource s) async { final xFile = await _picker.pickImage(source: s, imageQuality: 50); if (xFile != null) setState(() => _imageFile = File(xFile.path)); }

  Widget _buildSubmitButton() => SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _urgency == 'ถึงแก่ชีวิต' ? Colors.red : Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _selectedCategory == null ? null : () {
    print('TITLE: ${_titleController.text}'); // เพิ่ม log ดูค่าหัวข้อ
    print('REPORT: $_selectedCategory | URGENCY: $_urgency');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: _urgency == 'ถึงแก่ชีวิต' ? Colors.red : Colors.blueAccent, content: Text('ส่งข้อมูลด่วนระดับ $_urgency ให้กู้ภัยแล้ว!')));
    Navigator.pop(context);
  }, child: Text(_urgency == 'ถึงแก่ชีวิต' ? 'แจ้งเหตุด่วนถึงแก่ชีวิตทันที!' : 'ส่งแจ้งเหตุสถานการณ์', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))));
}