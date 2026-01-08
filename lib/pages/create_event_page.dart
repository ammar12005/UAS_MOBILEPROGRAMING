import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../database/hive_service.dart';

class CreateEventPage extends StatefulWidget {
  final Function(Event) onEventCreated;
  const CreateEventPage({super.key, required this.onEventCreated});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _n = TextEditingController();
  final _l = TextEditingController();
  final _c = TextEditingController();
  final _p = TextEditingController();
  final _d = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  
  bool _isSaving = false;

  @override
  void dispose() {
    _n.dispose();
    _l.dispose();
    _c.dispose();
    _p.dispose();
    _d.dispose();
    super.dispose();
  }

  // Metode pemilih tanggal yang hilang di kode sebelumnya
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute);
      });
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final newEvent = Event(
          id: DateTime.now().millisecondsSinceEpoch,
          name: _n.text.trim(),
          date: _date,
          location: _l.text.trim(),
          capacity: int.tryParse(_c.text) ?? 0,
          price: double.tryParse(_p.text) ?? 0.0,
          description: _d.text.trim(),
          ticketsSold: 0,
        );
        
        await HiveService.createEvent(newEvent);
        widget.onEventCreated(newEvent);
        
        if (mounted) {
          Navigator.pop(context, newEvent);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event berhasil disimpan ke Hive!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Event Baru")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _n, 
              decoration: const InputDecoration(labelText: "Nama Event"),
              validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
            ),
            TextFormField(
              controller: _l, 
              decoration: const InputDecoration(labelText: "Lokasi"),
              validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
            ),
            ListTile(
              title: Text("Tanggal: ${DateFormat('dd MMM yyyy').format(_date)}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _c, 
              decoration: const InputDecoration(labelText: "Kapasitas"),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _p, 
              decoration: const InputDecoration(labelText: "Harga"),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _d, 
              decoration: const InputDecoration(labelText: "Deskripsi"),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _createEvent,
              child: _isSaving 
                ? const CircularProgressIndicator() 
                : const Text("Simpan Event"),
            ),
          ],
        ),
      ),
    );
  }
} // TUTUP KELAS STATE - Ini yang sering hilang di gambar Anda