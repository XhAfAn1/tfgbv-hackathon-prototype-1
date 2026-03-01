import 'package:flutter/material.dart';

class MapSelectionWidget extends StatefulWidget {
  final Function(String?) onNgoSelected;

  const MapSelectionWidget({super.key, required this.onNgoSelected});

  @override
  State<MapSelectionWidget> createState() => _MapSelectionWidgetState();
}

class _MapSelectionWidgetState extends State<MapSelectionWidget> {
  // Mock NGO Data
  final List<Map<String, dynamic>> _dummyNgos = [
    {'id': 'ngo_1', 'name': 'Talk Safe Admin Center', 'distance': '1.2km'},
    {'id': 'ngo_2', 'name': 'Women Helpline Foundation', 'distance': '3.4km'},
    {'id': 'ngo_3', 'name': 'Cyber Peace Clinic', 'distance': '5.0km'},
  ];

  String? _selectedNgoId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select an NGO (Or let AI decide)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200, // Fixed height for the list to act like a map view
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            itemCount: _dummyNgos.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final ngo = _dummyNgos[index];
              return ListTile(
                title: Text(ngo['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Distance: ${ngo['distance']}'),
                trailing: _selectedNgoId == ngo['id']
                    ? const Icon(Icons.check_circle, color: Colors.lightBlue)
                    : const Icon(Icons.circle_outlined),
                onTap: () {
                  setState(() => _selectedNgoId = ngo['id']);
                  widget.onNgoSelected(_selectedNgoId);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            setState(() => _selectedNgoId = null);
            widget.onNgoSelected(null); // null means "Let AI Decide"
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AI Auto-Match Selected')),
            );
          },
          icon: const Icon(Icons.psychology),
          label: const Text('Let AI Decide (Recommended)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedNgoId == null ? Colors.lightBlue[50] : Colors.white,
            foregroundColor: Colors.lightBlue,
            side: const BorderSide(color: Colors.lightBlue),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
