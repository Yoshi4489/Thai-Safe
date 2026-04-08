import 'dart:convert';

class IncidentFormatHelper {
  // แปลงประเภทเหตุการณ์เป็นภาษาไทย 
  static String getIncidentTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return '🔥 อัคคีภัย (ไฟไหม้)';
      case 'flood': return '🌊 อุทกภัย (น้ำท่วม)';
      case 'collapse': return '🏢 อาคารถล่ม/แผ่นดินไหว';
      case 'chemical': return '🧪 สารเคมีรั่วไหล';
      case 'violence': return '⚠️ เหตุร้าย/ความรุนแรง';
      case 'other': return '🆘 เหตุอื่นๆ';
      case 'accident': return '🚗 อุบัติเหตุ';
      case 'crime': return '🔪 อาชญากรรม';
      case 'medical': return '🚑 ป่วยฉุกเฉิน';
      default: return '⚠️ เหตุอื่นๆ ($type)';
    }
  }

  // แปลง Map Details ให้เป็น String เพื่อไปแสดงผลใน Bottom Sheet
  static String formatIncidentDetails(dynamic rawDetails) {
    if (rawDetails == null) return 'ไม่มีข้อมูลรายละเอียดเพิ่มเติม';

    Map<String, dynamic> details = {};
    
    if (rawDetails is String) {
      try {
        details = jsonDecode(rawDetails);
      } catch (_) {
        return rawDetails.toString(); 
      }
    } else if (rawDetails is Map) {
      details = Map<String, dynamic>.from(rawDetails);
    } else {
      return 'ไม่มีข้อมูลรายละเอียดเพิ่มเติม';
    }

    if (details.isEmpty) return 'ไม่มีข้อมูลรายละเอียดเพิ่มเติม';
    
    List<String> formattedList = [];
    
    details.forEach((key, value) {
      // ดักจับข้ามค่าที่ว่าง null หรือ Array ว่าง
      if (value == null || value.toString().trim().isEmpty || value.toString() == 'null' || value.toString() == '[]') return;

      String cleanKey = key.trim(); 
      String thKey = cleanKey;
      String thValue = value.toString();
      
      switch (cleanKey) {
        // ================= ทั่วไป / อัคคีภัย / อุทกภัย =================
        case 'fire_type': thKey = 'ลักษณะที่เกิดเหตุ'; break;
        case 'status': thKey = 'สถานการณ์'; break;
        case 'has_people_waiting':
        case 'has_people__waiting':
          thKey = 'ผู้รอความช่วยเหลือ';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'people_count':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนผู้ประสบเหตุ'; thValue = '$value คน'; break;
        case 'has_electricity':
          thKey = 'ไฟฟ้า';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี (ใช้งานได้)' : 'ไม่มี (ถูกตัด)';
          break;
        case 'has_bedridden':
          thKey = 'ผู้ป่วยติดเตียง';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'water_current': thKey = 'กระแสน้ำ'; break;
        case 'boat_access': thKey = 'รถ/เรือเข้าถึงได้'; break;
        case 'supplies_status': thKey = 'สถานะเสบียง/น้ำดื่ม'; break;
        case 'medical_needs':
          thKey = 'ความต้องการทางการแพทย์';
          Map<String, dynamic> medMap = {};
          if (value is Map) {
            medMap = Map<String, dynamic>.from(value);
          } else if (value is String) {
            try { medMap = jsonDecode(value); } catch (_) {}
          }
          if (medMap.isNotEmpty) {
            List<String> meds = [];
            bool needMeds = (medMap['need_meds'] == true || medMap['need_meds'].toString() == 'true');
            bool severe = (medMap['severe_disease'] == true || medMap['severe_disease'].toString() == 'true');
            if (needMeds) meds.add('ต้องการยา: ${medMap['med_name'] ?? 'ไม่ระบุ'}');
            if (severe) meds.add('โรคประจำตัว: ${medMap['disease_name'] ?? 'ไม่ระบุ'}');
            thValue = meds.isEmpty ? 'ไม่มีความต้องการพิเศษ' : meds.join(', ');
          } else {
            thValue = 'ไม่มี';
          }
          break;

        // ================= สารเคมีรั่วไหล =================
        case 'characteristics': thKey = 'ลักษณะสารเคมี'; break;
        case 'color': thKey = 'สี'; break;
        case 'symptoms': thKey = 'อาการผู้ได้รับผลกระทบ'; break;
        case 'wind_direction': thKey = 'ทิศทางลม'; break;
        case 'affected_area': thKey = 'พื้นที่ได้รับผลกระทบ'; break;

        // ================= เหตุร้าย / กราดยิง / ความรุนแรง =================
        case 'type': thKey = 'ลักษณะเหตุการณ์'; break;
        case 'weapon': thKey = 'อาวุธที่ใช้'; break;
        case 'suspect_status': thKey = 'สถานะผู้ก่อเหตุ'; break;
        case 'fled_vehicle_detail': thKey = 'ยานพาหนะหลบหนี'; break;
        case 'suspect_info': thKey = 'รูปพรรณผู้ก่อเหตุ'; break;
        case 'injury_type': thKey = 'ลักษณะบาดแผล'; break;
        case 'reporter_safety': thKey = 'สถานะความปลอดภัยผู้แจ้ง'; break;

        // ================= อาคารถล่ม / แผ่นดินไหว =================
        case 'feeling': thKey = 'การรับรู้ถึงแรงสั่นสะเทือน'; break;
        case 'damage': thKey = 'ความเสียหายของอาคาร'; break;
        case 'secondary_risk': thKey = 'ความเสี่ยงซ้ำซ้อน'; break;
        case 'utilities_status':
          thKey = 'ระบบสาธารณูปโภค';
          if (value is List) {
            thValue = value.join(', ');
          } else if (value is String) {
            thValue = value.replaceAll('[', '').replaceAll(']', '');
          }
          break;

        // ================= ข้อมูลผู้บาดเจ็บ / ผลกระทบ (ใช้ร่วมกันหลายเหตุ) =================
        case 'has_injured':
          thKey = 'ผู้บาดเจ็บ';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'injured_count':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนผู้บาดเจ็บ'; thValue = '$value คน'; break;
        case 'has_affected':
          thKey = 'ผู้ได้รับผลกระทบ';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'affected_count':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนผู้ได้รับผลกระทบ'; thValue = '$value คน'; break;
        case 'has_trapped':
          thKey = 'มีคนติดอยู่';
          thValue = (value == true || value.toString().toLowerCase() == 'true') ? 'มี' : 'ไม่มี';
          break;
        case 'trapped_count':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนคนติด'; thValue = '$value คน'; break;
        case 'building_floors':
          if (value == 0 || value.toString() == '0') return;
          thKey = 'จำนวนชั้นอาคาร'; thValue = '$value ชั้น'; break;

        // ================= อื่น ๆ =================
        case 'nearby_risk': thKey = 'ความเสี่ยงพื้นที่ข้างเคียง'; break;
        case 'water_source': thKey = 'แหล่งน้ำใกล้เคียง'; break;
        case 'extra_note': thKey = 'หมายเหตุเพิ่มเติม'; break;
        case 'urgent_needs':
          thKey = 'ต้องการความช่วยเหลือด่วน';
          if (value is List) {
            thValue = value.join(', ');
          } else if (value is String) {
            try { 
              List<dynamic> parsedList = jsonDecode(value);
              thValue = parsedList.join(', '); 
            } catch (_) {}
          }
          break;
        case 'action_by': thKey = 'เจ้าหน้าที่รับเรื่อง'; break;
        case 'action_time':
          thKey = 'เวลาอัปเดตสถานะ';
          try {
             thValue = DateTime.parse(value.toString()).toLocal().toString().substring(0, 16);
          } catch (_) {}
          break;
      }
      formattedList.add('• $thKey: $thValue');
    });
    
    return formattedList.join('\n');
  }
}