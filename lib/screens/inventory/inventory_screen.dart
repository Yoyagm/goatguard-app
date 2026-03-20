import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/device.dart';
import '../../providers/device_provider.dart';
import '../../providers/mock_data.dart';
import '../../widgets/cards/device_tile.dart';

enum DeviceFilter { all, withAgent, arpOnly, withAlerts }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  DeviceFilter _filter = DeviceFilter.all;
  String _search = '';
  final _searchController = TextEditingController();

  List<Device> _applyFilters(List<Device> devices) {
    var result = devices;

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              d.ipAddress.contains(q) ||
              d.macAddress.toLowerCase().contains(q))
          .toList();
    }

    switch (_filter) {
      case DeviceFilter.withAgent:
        return result
            .where((d) => d.coverage == DeviceCoverage.withAgent)
            .toList();
      case DeviceFilter.arpOnly:
        return result
            .where((d) => d.coverage == DeviceCoverage.arpOnly)
            .toList();
      case DeviceFilter.withAlerts:
        return result.where((d) => d.alertCount > 0).toList();
      case DeviceFilter.all:
        return result;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceProv = context.watch<DeviceProvider>();

    // Fallback a MockData si la API aún no responde
    final allDevices = deviceProv.devices.isNotEmpty
        ? deviceProv.devices
        : MockData.devices;
    final devices = _applyFilters(allDevices);

    final withAgent =
        devices.where((d) => d.coverage == DeviceCoverage.withAgent).toList();
    final arpOnly =
        devices.where((d) => d.coverage == DeviceCoverage.arpOnly).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search devices...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textTertiary, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textTertiary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // Filter Chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: DeviceFilter.values.map((f) {
              final selected = _filter == f;
              final label = switch (f) {
                DeviceFilter.all => 'All',
                DeviceFilter.withAgent => 'With Agent',
                DeviceFilter.arpOnly => 'ARP Only',
                DeviceFilter.withAlerts => 'Alerts',
              };
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: selected,
                  label: Text(label),
                  labelStyle: GoogleFonts.inter(
                    color: selected ? AppColors.base : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.brand,
                  side: BorderSide(
                    color: selected
                        ? AppColors.brand
                        : const Color(0xFF30363D),
                    width: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  showCheckmark: false,
                  onSelected: (_) =>
                      setState(() => _filter = selected ? DeviceFilter.all : f),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Device List
        Expanded(
          child: RefreshIndicator(
            color: AppColors.brand,
            backgroundColor: AppColors.surface,
            onRefresh: () => deviceProv.fetchDevices(),
            child: ListView(
              children: [
                if (_filter == DeviceFilter.all ||
                    _filter == DeviceFilter.withAgent) ...[
                  if (withAgent.isNotEmpty)
                    _sectionLabel('WITH AGENT (${withAgent.length})'),
                  ...withAgent.map((d) => DeviceTile(
                        device: d,
                        onTap: () => Navigator.of(context)
                            .pushNamed('/device', arguments: d),
                      )),
                ],
                if ((_filter == DeviceFilter.all ||
                        _filter == DeviceFilter.arpOnly) &&
                    arpOnly.isNotEmpty) ...[
                  _sectionLabel('ARP ONLY - NO AGENT (${arpOnly.length})'),
                  ...arpOnly.map((d) => DeviceTile(
                        device: d,
                        onTap: () => Navigator.of(context)
                            .pushNamed('/device', arguments: d),
                      )),
                ],
                if (_filter == DeviceFilter.withAlerts) ...[
                  ...devices.map((d) => DeviceTile(
                        device: d,
                        onTap: () => Navigator.of(context)
                            .pushNamed('/device', arguments: d),
                      )),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
