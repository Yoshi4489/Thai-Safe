import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:thai_safe/core/services/cloudinary_provider.dart';

import 'package:thai_safe/features/authentication/presentation/signup_phone_page.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/incidents/controllers/incident_controller.dart';

import 'package:thai_safe/features/incidents/presentation/widgets/incident_map_picker.dart';
import 'package:thai_safe/features/incidents/presentation/widgets/incident_form_helpers.dart';
import 'package:thai_safe/features/incidents/presentation/widgets/incident_category_forms.dart';

class ReportIncidentPage extends ConsumerStatefulWidget {
  final LatLng currentLocation;
  const ReportIncidentPage({super.key, this.currentLocation = const LatLng(13.7649, 100.5383)});

  @override
  ConsumerState<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends ConsumerState<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();

  // สร้าง Key เพื่อไปดึงข้อมูลจาก Form ย่อย ตอนกด Submit
  final _floodKey = GlobalKey<FloodFormWidgetState>();
  final _fireKey = GlobalKey<FireFormWidgetState>();
  final _collapseKey = GlobalKey<CollapseFormWidgetState>();
  final _chemicalKey = GlobalKey<ChemicalFormWidgetState>();
  final _violenceKey = GlobalKey<ViolenceFormWidgetState>();
  final _otherKey = GlobalKey<OtherFormWidgetState>();

  String? _selectedCategory;
  File? _imageFile;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  late LatLng _selectedLocation;
  String _urgency = 'รอได้';
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'fire', 'label': 'ไฟไหม้', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'id': 'flood', 'label': 'น้ำท่วม', 'icon': Icons.flood, 'color': Colors.blueAccent},
    {'id': 'collapse', 'label': 'แผ่นดินไหว', 'icon': Icons.domain_disabled, 'color': Colors.brown},
    {'id': 'chemical', 'label': 'สารเคมีรั่ว', 'icon': Icons.science, 'color': Colors.purple},
    {'id': 'violence', 'label': 'เหตุร้าย', 'icon': Icons.warning_amber, 'color': Colors.red},
    {'id': 'other', 'label': 'อื่นๆ', 'icon': Icons.sos, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  // ==========================================
  // UI Builder Methods
  // ==========================================
  Widget _buildCategoryGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSel = _selectedCategory == cat['id'];
          return InkWell(
            onTap: () => setState(() { _selectedCategory = cat['id']; _urgency = 'รอได้'; }),
            child: Container(
              decoration: BoxDecoration(color: isSel ? cat['color'].withOpacity(0.1) : Colors.white, border: Border.all(color: isSel ? cat['color'] : Colors.grey.shade300, width: isSel ? 2 : 1), borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(cat['icon'], color: isSel ? cat['color'] : Colors.grey), const SizedBox(height: 4), Text(cat['label'], style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center)])
            ),
          );
        },
      );

  Widget _buildUrgencyPicker() {
    final levels = ['รอได้', 'ด่วนมาก', 'ถึงแก่ชีวิต'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        IncidentFormHelpers.buildSectionHeader('ระดับความเร่งด่วน (Triage)'),
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
                    selectedColor: color.withOpacity(0.2), backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
                    onSelected: (val) => setState(() => _urgency = level),
                    labelStyle: TextStyle(color: isSelected ? color : Colors.black54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
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
    
    // เรียกใช้ฟอร์มจากไฟล์ incident_category_forms.dart
    Widget dynamicForm;
    switch (_selectedCategory) {
      case 'flood': dynamicForm = FloodFormWidget(key: _floodKey); break;
      case 'fire': dynamicForm = FireFormWidget(key: _fireKey); break;
      case 'collapse': dynamicForm = CollapseFormWidget(key: _collapseKey); break;
      case 'chemical': dynamicForm = ChemicalFormWidget(key: _chemicalKey); break;
      case 'violence': dynamicForm = ViolenceFormWidget(key: _violenceKey); break;
      case 'other': dynamicForm = OtherFormWidget(key: _otherKey); break;
      default: dynamicForm = const SizedBox.shrink();
    }

    Color bgAlertColor = _urgency == 'ถึงแก่ชีวิต' ? Colors.red.withOpacity(0.1) : (_urgency == 'ด่วนมาก' ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.05));
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16), padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: bgAlertColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: _urgency == 'ถึงแก่ชีวิต' ? Colors.red : (_urgency == 'ด่วนมาก' ? Colors.orange : Colors.blue.shade200), width: 1.5)),
      child: Column(children: [dynamicForm, _buildUrgencyPicker()]),
    );
  }

  // ==========================================
  // Main Build
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('แจ้งเหตุฉุกเฉิน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person, size: 80, color: Colors.grey), const SizedBox(height: 24),
                Text('กรุณาเข้าสู่ระบบ', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
                const Text('กรุณาเข้าสู่ระบบก่อนทำการแจ้งเหตุ เพื่อให้เจ้าหน้าที่สามารถยืนยันตัวตน และติดต่อกลับได้', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)), const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignupPhonePage())), child: const Text('กลับ / เข้าสู่ระบบ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งเหตุฉุกเฉิน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. สถานที่เกิดเหตุ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // เรียกใช้ Map Component 
              IncidentMapPicker(
                initialLocation: _selectedLocation,
                onLocationChanged: (newPos) => _selectedLocation = newPos,
              ),
              
              const SizedBox(height: 24),
              Text('2. ข้อมูลเหตุการณ์และระดับความเร่งด่วน', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildCategoryGrid(),
              AnimatedSize(duration: const Duration(milliseconds: 300), child: _buildDynamicFields()),
              const SizedBox(height: 10),
              Text('3. ภาพถ่ายและรายละเอียด', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // Image Picker
              GestureDetector(onTap: () => showModalBottomSheet(context: context, builder: (c) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.camera_alt), title: const Text('ถ่ายรูป'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.camera); }), ListTile(leading: const Icon(Icons.photo_library), title: const Text('อัลบั้ม'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.gallery); })]))), child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: _imageFile == null ? const Icon(Icons.add_a_photo, color: Colors.grey) : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover)))),
              
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'หัวข้อเหตุการณ์ *',
                  hintText: 'เช่น ไฟไหม้บ้านไม้ / น้ำท่วมสูง',
                  prefixIcon: const Icon(Icons.title, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'กรุณาระบุหัวข้อเหตุการณ์' : null,
              ),
              
              const SizedBox(height: 16),

              TextFormField(
                controller: _detailController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'รายละเอียดเพิ่มเติม',
                  hintText: 'พิมพ์รายละเอียดเพิ่มเติมที่นี่...',
                  alignLabelWithHint: true, // ทำให้ Label ลอยอยู่ด้านบนเมื่อมีหลายบรรทัด
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _urgency == 'ถึงแก่ชีวิต' ? Colors.red : (_urgency == 'ด่วนมาก' ? Colors.orange : Colors.blueAccent), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _selectedCategory == null ? null : _submitReport, child: Text(_urgency == 'ถึงแก่ชีวิต' ? 'แจ้งเหตุด่วนถึงแก่ชีวิตทันที!' : 'ส่งแจ้งเหตุสถานการณ์', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource s) async { 
    final xFile = await _picker.pickImage(source: s, imageQuality: 50);
    if (xFile != null) setState(() => _imageFile = File(xFile.path)); 
  }

  // ==========================================
  // LOGIC ส่งข้อมูล
  // ==========================================
  void _submitReport() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาตรวจสอบข้อมูลช่องสีแดงให้ครบถ้วน'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      return;
    }

    // ดึงข้อมูลจากฟอร์มย่อย 
    Map<String, dynamic> specificData = {};
    switch (_selectedCategory) {
      case 'flood': specificData = _floodKey.currentState?.getFormData() ?? {}; break;
      case 'fire': specificData = _fireKey.currentState?.getFormData() ?? {}; break;
      case 'collapse': specificData = _collapseKey.currentState?.getFormData() ?? {}; break;
      case 'chemical': specificData = _chemicalKey.currentState?.getFormData() ?? {}; break;
      case 'violence': specificData = _violenceKey.currentState?.getFormData() ?? {}; break;
      case 'other': specificData = _otherKey.currentState?.getFormData() ?? {}; break;
    }
    
    // ใส่ detail เสริมลงใน specificData สำหรับ case 'other' (หรือทุกเคสก็ได้)
    if (_selectedCategory == 'other') {
      specificData['extra_note'] = _detailController.text.trim();
    }

    try {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      late String res = '';
      if (_imageFile != null) {
        res = await ref.read(cloudinaryServiceProvider).uploadImage(_imageFile!);
      }

      final reporterFullName = '${user.firstName} ${user.lastName}'.trim();
      final reporterName = reporterFullName.isEmpty ? 'ไม่ระบุชื่อ' : reporterFullName;
      
      await ref.read(incidentControllerProvider.notifier).reportIncident(
            title: _titleController.text.trim(),
            type: _selectedCategory!,
            details: specificData,
            urgency: _urgency,
            lat: _selectedLocation.latitude,
            lng: _selectedLocation.longitude,
            imageUrls: res.isNotEmpty ? [res] : [],
            userId: user.id,
            reporterName: reporterName,
            reporterTel: user.tel,
          );
          
      if (mounted) {
        Navigator.pop(context); Navigator.pop(context);
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