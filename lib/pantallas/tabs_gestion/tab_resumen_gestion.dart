// lib/pantallas/tabs_gestion/tab_resumen_gestion.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:fl_chart/fl_chart.dart'; 

class TabResumenGestion extends StatefulWidget {
  const TabResumenGestion({super.key});

  @override
  State<TabResumenGestion> createState() => _TabResumenGestionState();
}

class _TabResumenGestionState extends State<TabResumenGestion> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 6));
  DateTime _fechaFin = DateTime.now();
  String _filtroActivo = '7dias'; 

  // Estados de los filtros de tarjetas (0:Total, 1:Efectivo, 2:Digital)
  int _filtroVentasIndex = 0; 
  int _filtroGastosIndex = 0;

  final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  String _formatearMoneda(double valor, {bool compacto = false}) {
    if (compacto) {
      return NumberFormat.compact(locale: 'es').format(valor);
    }
    return currencyFormat.format(valor);
  }

  void _cambiarFiltro(String filtro) {
    final ahora = DateTime.now();
    DateTime inicio;
    DateTime fin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59); 

    if (filtro == 'hoy') {
      inicio = DateTime(ahora.year, ahora.month, ahora.day); 
    } else if (filtro == '7dias') {
      inicio = ahora.subtract(const Duration(days: 6));
      inicio = DateTime(inicio.year, inicio.month, inicio.day); 
    } else if (filtro == '30dias') {
      inicio = ahora.subtract(const Duration(days: 29));
      inicio = DateTime(inicio.year, inicio.month, inicio.day);
    } else {
      inicio = ahora.subtract(const Duration(days: 6)); 
    }

    setState(() {
      _fechaInicio = inicio;
      _fechaFin = fin;
      _filtroActivo = filtro;
    });
  }

  Future<void> _elegirRangoPersonalizado() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, 
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() {
        _fechaInicio = rango.start;
        _fechaFin = DateTime(rango.end.year, rango.end.month, rango.end.day, 23, 59, 59);
        _filtroActivo = 'personalizado';
      });
    }
  }

  // --- DETALLE COMPLETO (MODAL) ---
  void _mostrarDetalleCompleto(Map<String, dynamic> data) {
    final fecha = (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
    final fondoInicial = (data['fondo_inicial'] ?? 0.0).toDouble();
    final vEf = (data['ventas_efectivo'] ?? 0.0).toDouble();
    final vDig = (data['ventas_otros'] ?? 0.0).toDouble();
    final gEf = (data['gastos_efectivo'] ?? 0.0).toDouble();
    final gDig = (data['gastos_digital'] ?? 0.0).toDouble();
    final totalReal = (data['total_real_contado'] ?? 0.0).toDouble();
    final totalSistema = (data['total_calculado_caja'] ?? 0.0).toDouble();
    final diferencia = (data['diferencia'] ?? 0.0).toDouble();
    final notas = data['notas'] ?? '';
    final colorPrimario = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Text('Detalle del Cierre', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                Text(DateFormat('EEEE d MMMM, yyyy \nHH:mm a', 'es').format(fecha).toUpperCase(), style: TextStyle(color: colorPrimario, fontWeight: FontWeight.bold, fontSize: 20)),
                const Divider(height: 40),
                _TituloSeccion('Entradas', Icons.trending_up, Colors.green),
                _FilaDetalle('Fondo Inicial', fondoInicial),
                _FilaDetalle('Ventas Efectivo', vEf),
                _FilaDetalle('Ventas Digitales', vDig, esAzul: true),
                _FilaDetalle('TOTAL INGRESOS', fondoInicial + vEf + vDig, esNegrita: true),
                const SizedBox(height: 20),
                _TituloSeccion('Salidas', Icons.trending_down, Colors.red.shade300),
                _FilaDetalle('Gastos Efectivo', gEf),
                _FilaDetalle('Gastos Digitales', gDig, esAzul: true),
                _FilaDetalle('TOTAL GASTOS', gEf + gDig, esNegrita: true),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(children: [Text('Cuadre de Efectivo', style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimario)), const SizedBox(height: 10), _FilaDetalle('Sistema Esperaba:', totalSistema), _FilaDetalle('Tú contaste:', totalReal), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('DIFERENCIA:', style: TextStyle(fontWeight: FontWeight.bold)), Text(diferencia > 0 ? '+${_formatearMoneda(diferencia)}' : _formatearMoneda(diferencia), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: diferencia >= 0 ? Colors.green : Colors.red))])]),
                ),
                if (notas.isNotEmpty) ...[const SizedBox(height: 25), const Text('Notas:', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 5), Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(10)), child: Text(notas, style: TextStyle(color: Colors.brown.shade800, fontStyle: FontStyle.italic)))],
                const SizedBox(height: 30),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')))
              ],
            );
          },
        );
      }
    );
  }

  Widget _TituloSeccion(String titulo, IconData icon, Color color) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 8), Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]));
  Widget _FilaDetalle(String label, double valor, {bool esNegrita = false, bool esAzul = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: esNegrita ? FontWeight.bold : FontWeight.normal)), Text(_formatearMoneda(valor), style: TextStyle(fontWeight: esNegrita ? FontWeight.bold : FontWeight.normal, color: esAzul ? Colors.blue.shade700 : Colors.black))]));

  @override
  Widget build(BuildContext context) {
    final formatoRango = DateFormat('d MMM', 'es');
    final tituloRango = '${formatoRango.format(_fechaInicio)} - ${formatoRango.format(_fechaFin)}';

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cierres_caja')
            .where('fecha', isGreaterThanOrEqualTo: _fechaInicio)
            .where('fecha', isLessThanOrEqualTo: _fechaFin)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          if (snapshot.hasError) return const Center(child: Text('Error al cargar datos.'));
          final cierres = snapshot.data?.docs ?? [];
          return _buildDashboard(context, cierres, tituloRango);
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<QueryDocumentSnapshot> cierres, String tituloRango) {
    // 1. CÁLCULOS GLOBALES
    double ventasEfectivo = 0, ventasDigital = 0;
    double gastosEfectivo = 0, gastosDigital = 0;
    double totalDiferencia = 0;

    for (var doc in cierres) {
      final data = doc.data() as Map<String, dynamic>;
      ventasEfectivo += (data['ventas_efectivo'] ?? 0.0);
      ventasDigital += (data['ventas_otros'] ?? 0.0);
      gastosEfectivo += (data['gastos_efectivo'] ?? 0.0);
      gastosDigital += (data['gastos_digital'] ?? 0.0);
      totalDiferencia += (data['diferencia'] ?? 0.0);
    }
    final totalVendido = ventasEfectivo + ventasDigital;
    final totalGastos = gastosEfectivo + gastosDigital;
    final gananciaNeta = totalVendido - totalGastos;

    final colorPrimario = Theme.of(context).colorScheme.primary; 
    final colorMenta = Theme.of(context).colorScheme.secondary; 

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILTROS SUPERIORES
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(tituloRango, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorPrimario, fontWeight: FontWeight.bold)), IconButton(icon: Icon(Icons.calendar_month_outlined, color: colorPrimario), onPressed: _elegirRangoPersonalizado)]),
            const SizedBox(height: 10),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_buildFilterChip('Hoy', 'hoy'), const SizedBox(width: 8), _buildFilterChip('7 Días', '7dias'), const SizedBox(width: 8), _buildFilterChip('30 Días', '30dias')])),
            
            const SizedBox(height: 24),

            // TARJETAS INTERACTIVAS (KPIs)
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.3, 
              children: [
                _buildInteractiveCard(tituloBase: 'Ventas', color: colorMenta, indexState: _filtroVentasIndex, total: totalVendido, efectivo: ventasEfectivo, digital: ventasDigital, onTap: () => setState(() => _filtroVentasIndex = (_filtroVentasIndex + 1) % 3)),
                _buildInteractiveCard(tituloBase: 'Gastos', color: Colors.red.shade300, indexState: _filtroGastosIndex, total: totalGastos, efectivo: gastosEfectivo, digital: gastosDigital, onTap: () => setState(() => _filtroGastosIndex = (_filtroGastosIndex + 1) % 3)),
                _buildStaticCard('Ganancia Neta', gananciaNeta, Icons.savings, colorMenta),
                _buildStaticCard('Diferencia', totalDiferencia, Icons.sync_alt, totalDiferencia >= 0 ? colorMenta : Colors.red.shade300),
              ],
            ),
            
            const SizedBox(height: 32),

            // --- GRÁFICO 1: BARRAS (INGRESOS VS GASTOS) ---
            Text('Comparativa Diaria', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(height: 220, padding: const EdgeInsets.fromLTRB(16, 24, 16, 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)), child: cierres.isEmpty ? Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade400))) : BarChart(_crearDatosBarras(cierres, context))),

            const SizedBox(height: 32),

            // --- GRÁFICO 2: LÍNEA (TENDENCIA DE CRECIMIENTO) ¡NUEVO! ---
            Row(
              children: [
                Icon(Icons.show_chart, color: colorPrimario),
                const SizedBox(width: 8),
                Text('Tendencia de Ganancia', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            Text('¿Cómo va el negocio? (Ganancia Neta)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              height: 220, 
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 10), 
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.white, colorMenta.withOpacity(0.05)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: Colors.grey.shade100)
              ), 
              child: cierres.isEmpty 
                  ? Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade400))) 
                  : LineChart(_crearDatosLinea(cierres, context)),
            ),

            const SizedBox(height: 32),

            // HISTORIAL
            Text('Historial Detallado', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (cierres.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay cierres registrados.')))
            else ListView.builder(
              itemCount: cierres.length, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final data = cierres[index].data() as Map<String, dynamic>;
                final fecha = (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
                final vEf = data['ventas_efectivo'] ?? 0.0;
                final vOt = data['ventas_otros'] ?? 0.0;
                final dif = data['diferencia'] ?? 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]),
                  child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(15), child: InkWell(borderRadius: BorderRadius.circular(15), onTap: () => _mostrarDetalleCompleto(data), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: Column(children: [Text(DateFormat('d').format(fecha), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(DateFormat('MMM').format(fecha).toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey))])), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Venta Total', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)), Text(_formatearMoneda((vEf + vOt).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Diferencia', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)), Text(dif > 0 ? '+${_formatearMoneda(dif.toDouble())}' : _formatearMoneda(dif.toDouble()), style: TextStyle(color: dif >= 0 ? colorMenta : Colors.red.shade300, fontWeight: FontWeight.bold))]), const SizedBox(width: 10), const Icon(Icons.chevron_right, color: Colors.grey)])))),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Tarjetas y Filtros) ---
  Widget _buildInteractiveCard({required String tituloBase, required Color color, required int indexState, required double total, required double efectivo, required double digital, required VoidCallback onTap}) {
    String titulo = indexState == 0 ? 'Total $tituloBase' : (indexState == 1 ? '$tituloBase (Efectivo)' : '$tituloBase (Digital)');
    double valor = indexState == 0 ? total : (indexState == 1 ? efectivo : digital);
    IconData icono = indexState == 0 ? (tituloBase == 'Ventas' ? Icons.trending_up : Icons.trending_down) : (indexState == 1 ? Icons.payments : Icons.qr_code);
    Color bgIcono = indexState == 0 ? color.withOpacity(0.1) : (indexState == 1 ? Colors.green.shade50 : Colors.blue.shade50);

    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))], border: indexState != 0 ? Border.all(color: color.withOpacity(0.5), width: 1.5) : null), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgIcono, shape: BoxShape.circle), child: Icon(icono, size: 20, color: color)), Icon(Icons.touch_app, size: 14, color: Colors.grey.shade300)]), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 4), AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Text(_formatearMoneda(valor, compacto: true), key: ValueKey(valor), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)))])]))));
  }

  Widget _buildStaticCard(String titulo, double valor, IconData icono, Color color) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icono, size: 28, color: color), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)), const SizedBox(height: 4), Text(_formatearMoneda(valor, compacto: true), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87))])]));

  Widget _buildFilterChip(String label, String filtroId) => ChoiceChip(label: Text(label), selected: _filtroActivo == filtroId, onSelected: (s) { if(s) _cambiarFiltro(filtroId); }, selectedColor: Theme.of(context).colorScheme.primary, backgroundColor: Colors.white, labelStyle: TextStyle(color: _filtroActivo == filtroId ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)));

  // --- LÓGICA DE GRÁFICOS ---
  
  // 1. Datos para Barras (Ventas vs Gastos)
  BarChartData _crearDatosBarras(List<QueryDocumentSnapshot> cierres, BuildContext context) {
    final Map<String, Map<String, double>> datos = {};
    final fmt = DateFormat('d MMM', 'es');
    for (var doc in cierres.reversed) {
      final d = doc.data() as Map<String, dynamic>;
      final dia = fmt.format((d['fecha'] as Timestamp).toDate());
      final v = (d['ventas_efectivo']??0.0) + (d['ventas_otros']??0.0);
      final g = (d['gastos_efectivo']??0.0) + (d['gastos_digital']??0.0);
      datos.putIfAbsent(dia, () => {'v':0.0, 'g':0.0});
      datos[dia]!['v'] = datos[dia]!['v']! + v;
      datos[dia]!['g'] = datos[dia]!['g']! + g;
    }
    
    // Tomar últimos 5 días
    final lista = datos.entries.length > 5 ? datos.entries.skip(datos.entries.length - 5) : datos.entries;
    List<BarChartGroupData> bars = [];
    Map<int, String> titles = {};
    int i = 0;
    
    for (var e in lista) {
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: e.value['v']!, color: Theme.of(context).colorScheme.secondary, width: 12, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: e.value['g']!, color: Colors.red.shade200, width: 12, borderRadius: BorderRadius.circular(4))
      ]));
      titles[i] = e.key;
      i++;
    }
    
    return BarChartData(alignment: BarChartAlignment.spaceAround, barGroups: bars, titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v,m)=>Text(_formatearMoneda(v, compacto: true), style: TextStyle(fontSize: 10, color: Colors.grey)))), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=>Text(titles[v.toInt()]??'', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)))), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))), borderData: FlBorderData(show: false), gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v)=>FlLine(color: Colors.grey.shade100, strokeWidth: 1)));
  }

  // 2. Datos para Línea (Tendencia Ganancia) ¡NUEVO!
  LineChartData _crearDatosLinea(List<QueryDocumentSnapshot> cierres, BuildContext context) {
    final Map<String, double> datos = {};
    final fmt = DateFormat('d MMM', 'es');
    
    // Ordenar de antiguo a nuevo
    for (var doc in cierres.reversed) {
      final d = doc.data() as Map<String, dynamic>;
      final dia = fmt.format((d['fecha'] as Timestamp).toDate());
      final v = (d['ventas_efectivo']??0.0) + (d['ventas_otros']??0.0);
      final g = (d['gastos_efectivo']??0.0) + (d['gastos_digital']??0.0);
      final ganancia = v - g; // Ganancia Neta
      
      datos.putIfAbsent(dia, () => 0.0);
      datos[dia] = datos[dia]! + ganancia;
    }

    final lista = datos.entries.length > 7 ? datos.entries.skip(datos.entries.length - 7) : datos.entries;
    List<FlSpot> spots = [];
    Map<int, String> titles = {};
    int i = 0;

    for (var e in lista) {
      spots.add(FlSpot(i.toDouble(), e.value));
      titles[i] = e.key;
      i++;
    }

    return LineChartData(
      lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipItems: (spots) {
        return spots.map((spot) => LineTooltipItem('${titles[spot.x.toInt()]}\n${_formatearMoneda(spot.y)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList();
      },  tooltipPadding: const EdgeInsets.all(8))),
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v)=>FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v,m)=>Padding(padding: const EdgeInsets.only(top: 8), child: Text(titles[v.toInt()]??'', style: TextStyle(fontSize: 10, color: Colors.grey.shade600))))),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, getTitlesWidget: (v,m)=>Text(_formatearMoneda(v, compacto: true), style: TextStyle(fontSize: 9, color: Colors.grey.shade400)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).colorScheme.secondary, // Color Menta
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.secondary.withOpacity(0.15)), // Sombrea el área bajo la curva
        ),
      ],
    );
  }
}