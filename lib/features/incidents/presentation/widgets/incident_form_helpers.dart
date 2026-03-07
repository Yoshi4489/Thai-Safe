import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IncidentFormHelpers {
  static Widget buildSectionHeader(String title) => ListTile(
        leading: const Icon(Icons.analytics_outlined, color: Colors.redAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
      );

  static Widget buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      );

  static Widget buildSwitch(String title, bool val, Function(bool) onChanged) => SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: val,
        onChanged: onChanged,
        activeColor: Colors.redAccent,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );

  static Widget buildSegmented(List<String> opts, String selected, Function(String) onSelect) {
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
        ),
      ),
    );
  }

  static Widget buildDropdown(String label, List<String> items, String currentValue, Function(String?) onChanged) {
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

  static Widget buildNumberField(String label, TextEditingController controller, {String? suffix, bool validateNonZero = false}) {
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

  static Widget buildTextField(String label, TextEditingController controller, {String? hint}) {
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

  static Widget buildCheckbox(String title, bool val, Function(bool?) onChanged) => CheckboxListTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: val,
        onChanged: onChanged,
        activeColor: Colors.redAccent,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );
}