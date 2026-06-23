import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/auth_models.dart';
import '../models/wilayah_models.dart';
import '../services/wilayah_service.dart';
import '../theme/app_theme.dart';

/// Default map center when no coordinates are set yet — roughly the centroid of Indonesia.
const _defaultCenter = LatLng(-2.5, 118.0);

class EditableAddress {
  const EditableAddress({
    this.provinsi,
    this.kabupaten,
    this.kecamatan,
    this.kelurahan = '',
    this.kodePos = '',
    this.address = '',
    this.latitude,
    this.longitude,
  });

  final Provinsi? provinsi;
  final Kabupaten? kabupaten;
  final Kecamatan? kecamatan;
  final String kelurahan;
  final String kodePos;
  final String address;
  final double? latitude;
  final double? longitude;

  factory EditableAddress.fromSession(AuthSession? session) {
    if (session == null) return const EditableAddress();
    return EditableAddress(
      provinsi: session.provinsiId != null
          ? Provinsi(id: session.provinsiId!, kode: '', nama: session.provinsiNama ?? '')
          : null,
      kabupaten: session.kabupatenId != null
          ? Kabupaten(
              id: session.kabupatenId!,
              provinsiId: session.provinsiId ?? 0,
              kode: '',
              nama: session.kabupatenNama ?? '')
          : null,
      kecamatan: session.kecamatanId != null
          ? Kecamatan(
              id: session.kecamatanId!,
              kabupatenId: session.kabupatenId ?? 0,
              kode: '',
              nama: session.kecamatanNama ?? '')
          : null,
      kelurahan: session.kelurahan ?? '',
      kodePos: session.kodePos ?? '',
      address: session.address ?? '',
      latitude: session.latitude,
      longitude: session.longitude,
    );
  }
}

/// Reusable Provinsi/Kabupaten/Kecamatan + Kelurahan/Kode Pos/Alamat lengkap form with an
/// OpenStreetMap pin picker. Used by both the profile "Alamat" page and the order preview page.
class AddressEditorForm extends StatefulWidget {
  const AddressEditorForm({
    super.key,
    required this.initialAddress,
    required this.onChanged,
  });

  final EditableAddress initialAddress;
  final ValueChanged<EditableAddress> onChanged;

  @override
  State<AddressEditorForm> createState() => _AddressEditorFormState();
}

class _AddressEditorFormState extends State<AddressEditorForm> {
  final _wilayahService = WilayahService();
  final _mapController = MapController();

  late final TextEditingController _kelurahanCtrl;
  late final TextEditingController _kodePosCtrl;
  late final TextEditingController _addressCtrl;

  List<Provinsi> _provinsiList = [];
  List<Kabupaten> _kabupatenList = [];
  List<Kecamatan> _kecamatanList = [];
  Provinsi? _selectedProvinsi;
  Kabupaten? _selectedKabupaten;
  Kecamatan? _selectedKecamatan;
  bool _loadingProvinsi = false;
  bool _loadingKabupaten = false;
  bool _loadingKecamatan = false;
  bool _locating = false;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _kelurahanCtrl = TextEditingController(text: widget.initialAddress.kelurahan);
    _kodePosCtrl = TextEditingController(text: widget.initialAddress.kodePos);
    _addressCtrl = TextEditingController(text: widget.initialAddress.address);
    _latitude = widget.initialAddress.latitude;
    _longitude = widget.initialAddress.longitude;
    _loadProvinsiList();
  }

  @override
  void dispose() {
    _kelurahanCtrl.dispose();
    _kodePosCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  LatLng get _mapCenter =>
      (_latitude != null && _longitude != null) ? LatLng(_latitude!, _longitude!) : _defaultCenter;

  void _emitChange() {
    widget.onChanged(EditableAddress(
      provinsi: _selectedProvinsi,
      kabupaten: _selectedKabupaten,
      kecamatan: _selectedKecamatan,
      kelurahan: _kelurahanCtrl.text,
      kodePos: _kodePosCtrl.text,
      address: _addressCtrl.text,
      latitude: _latitude,
      longitude: _longitude,
    ));
  }

  Future<void> _loadProvinsiList() async {
    setState(() => _loadingProvinsi = true);
    try {
      final list = await _wilayahService.getProvinsiList();
      if (!mounted) return;
      final preselected = widget.initialAddress.provinsi;
      final matched = preselected == null
          ? null
          : list.where((p) => p.id == preselected.id).cast<Provinsi?>().firstOrNull;
      setState(() {
        _provinsiList = list;
        _selectedProvinsi = matched;
        _loadingProvinsi = false;
      });
      if (matched != null) {
        await _loadKabupatenList(matched.id, preselectId: widget.initialAddress.kabupaten?.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProvinsi = false);
      _showError('Gagal memuat daftar provinsi: $e');
    }
  }

  Future<void> _loadKabupatenList(int provinsiId, {int? preselectId}) async {
    setState(() => _loadingKabupaten = true);
    try {
      final list = await _wilayahService.getKabupatenList(provinsiId);
      if (!mounted) return;
      final matched =
          preselectId == null ? null : list.where((k) => k.id == preselectId).cast<Kabupaten?>().firstOrNull;
      setState(() {
        _kabupatenList = list;
        _selectedKabupaten = matched;
        _loadingKabupaten = false;
      });
      if (matched != null) {
        await _loadKecamatanList(matched.id, preselectId: widget.initialAddress.kecamatan?.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingKabupaten = false);
      _showError('Gagal memuat daftar kabupaten: $e');
    }
  }

  Future<void> _loadKecamatanList(int kabupatenId, {int? preselectId}) async {
    setState(() => _loadingKecamatan = true);
    try {
      final list = await _wilayahService.getKecamatanList(kabupatenId);
      if (!mounted) return;
      final matched =
          preselectId == null ? null : list.where((k) => k.id == preselectId).cast<Kecamatan?>().firstOrNull;
      setState(() {
        _kecamatanList = list;
        _selectedKecamatan = matched;
        _loadingKecamatan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingKecamatan = false);
      _showError('Gagal memuat daftar kecamatan: $e');
    }
  }

  Future<void> _onProvinsiChanged(Provinsi? provinsi) async {
    setState(() {
      _selectedProvinsi = provinsi;
      _selectedKabupaten = null;
      _selectedKecamatan = null;
      _kabupatenList = [];
      _kecamatanList = [];
    });
    _emitChange();
    if (provinsi != null) {
      await _loadKabupatenList(provinsi.id);
    }
  }

  Future<void> _onKabupatenChanged(Kabupaten? kabupaten) async {
    setState(() {
      _selectedKabupaten = kabupaten;
      _selectedKecamatan = null;
      _kecamatanList = [];
    });
    _emitChange();
    if (kabupaten != null) {
      await _loadKecamatanList(kabupaten.id);
    }
  }

  void _onKecamatanChanged(Kecamatan? kecamatan) {
    setState(() => _selectedKecamatan = kecamatan);
    _emitChange();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showError('Izin lokasi ditolak.');
        return;
      }

      final position = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, 16.0);
      setState(() {
        _latitude = latLng.latitude;
        _longitude = latLng.longitude;
      });
      _emitChange();
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal mengambil lokasi saat ini: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Provinsi', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Provinsi>(
          value: _selectedProvinsi,
          items: _provinsiList.map((p) => DropdownMenuItem(value: p, child: Text(p.nama))).toList(),
          onChanged: _loadingProvinsi ? null : _onProvinsiChanged,
          decoration: InputDecoration(hintText: _loadingProvinsi ? 'Memuat provinsi...' : 'Pilih provinsi'),
        ),
        const SizedBox(height: 14),
        const Text('Kabupaten/Kota', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Kabupaten>(
          value: _selectedKabupaten,
          items: _kabupatenList.map((k) => DropdownMenuItem(value: k, child: Text(k.nama))).toList(),
          onChanged: (_selectedProvinsi == null || _loadingKabupaten) ? null : _onKabupatenChanged,
          decoration: InputDecoration(
            hintText: _selectedProvinsi == null
                ? 'Pilih provinsi terlebih dahulu'
                : _loadingKabupaten
                    ? 'Memuat kabupaten/kota...'
                    : 'Pilih kabupaten/kota',
          ),
        ),
        const SizedBox(height: 14),
        const Text('Kecamatan', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Kecamatan>(
          value: _selectedKecamatan,
          items: _kecamatanList.map((k) => DropdownMenuItem(value: k, child: Text(k.nama))).toList(),
          onChanged: (_selectedKabupaten == null || _loadingKecamatan) ? null : _onKecamatanChanged,
          decoration: InputDecoration(
            hintText: _selectedKabupaten == null
                ? 'Pilih kabupaten/kota terlebih dahulu'
                : _loadingKecamatan
                    ? 'Memuat kecamatan...'
                    : 'Pilih kecamatan',
          ),
        ),
        const SizedBox(height: 14),
        const Text('Kelurahan/Desa', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _kelurahanCtrl,
          onChanged: (_) => _emitChange(),
          decoration: const InputDecoration(hintText: 'Nama kelurahan/desa'),
        ),
        const SizedBox(height: 14),
        const Text('Kode Pos', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _kodePosCtrl,
          keyboardType: TextInputType.number,
          maxLength: 10,
          onChanged: (_) => _emitChange(),
          decoration: const InputDecoration(hintText: 'Kode pos', counterText: ''),
        ),
        const SizedBox(height: 14),
        const Text('Alamat Lengkap', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _addressCtrl,
          maxLines: 3,
          onChanged: (_) => _emitChange(),
          decoration: const InputDecoration(hintText: 'Jalan, RT/RW, patokan'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text('Titik Lokasi', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, size: 16),
              label: const Text('Gunakan Lokasi Saat Ini'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Geser peta agar pin di tengah menunjukkan lokasi pengiriman.',
          style: const TextStyle(fontSize: 12, color: AppTheme.muted),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: _latitude != null ? 16.0 : 4.5,
                    onPositionChanged: (camera, hasGesture) {
                      _latitude = camera.center.latitude;
                      _longitude = camera.center.longitude;
                      if (hasGesture) _emitChange();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.gcommers.app',
                      maxNativeZoom: 19,
                    ),
                  ],
                ),
                const IgnorePointer(
                  child: Icon(Icons.location_pin, size: 44, color: Color(0xFF2F6C3F)),
                ),
              ],
            ),
          ),
        ),
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 6),
          Text(
            '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
        ],
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
