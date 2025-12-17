// lib/pantallas/tabs_gestion/tab_cierre_caja.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:cafeteria_inventario/widgets/dialogo_error.dart';
import 'package:cafeteria_inventario/widgets/dialogo_exito.dart';

class TabCierreCaja extends StatefulWidget {
  const TabCierreCaja({super.key});

  @override
  State<TabCierreCaja> createState() => _TabCierreCajaState();
}

class _TabCierreCajaState extends State<TabCierreCaja> {
  // Controladores
  final _fondoInicialController = TextEditingController();
  final _ventasEfectivoController = TextEditingController();
  final _ventasDigitalController = TextEditingController(); // Nequi/Bancos
  final _gastosEfectivoController = TextEditingController();
  final _gastosDigitalController = TextEditingController(); 
  final _totalRealEfectivoController = TextEditingController(); 
  final _notasController = TextEditingController();

  // Variables de cálculo
  double _totalCalculadoEfectivo = 0.0; 
  double _diferencia = 0.0; 
  
  DateTime _fechaSeleccionada = DateTime.now();
  bool _estaGuardando = false;

  final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void dispose() {
    _fondoInicialController.dispose();
    _ventasEfectivoController.dispose();
    _ventasDigitalController.dispose();
    _gastosEfectivoController.dispose();
    _gastosDigitalController.dispose();
    _totalRealEfectivoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE FECHA (Adaptada al tema) ---
  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, // Usa tu Gris/Coral
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
            dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  // --- LÓGICA DE CÁLCULO (Cuadre de Caja FÍSICA) ---
  void _calcularDiferencia() {
    final fondoInicial = double.tryParse(_fondoInicialController.text) ?? 0.0;
    final ventasEf = double.tryParse(_ventasEfectivoController.text) ?? 0.0;
    final gastosEf = double.tryParse(_gastosEfectivoController.text) ?? 0.0;
    final totalRealEf = double.tryParse(_totalRealEfectivoController.text) ?? 0.0;

    // Fórmula: Lo que tenías + Lo que vendiste en billetes - Lo que gastaste en billetes
    final deberiaHaber = (fondoInicial + ventasEf) - gastosEf;
    final dif = totalRealEf - deberiaHaber;

    setState(() {
      _totalCalculadoEfectivo = deberiaHaber;
      _diferencia = dif;
    });
  }

  // --- GUARDAR EN FIREBASE ---
  Future<void> _guardarCierre() async {
    final fondoInicial = double.tryParse(_fondoInicialController.text) ?? 0.0;
    final ventasEf = double.tryParse(_ventasEfectivoController.text) ?? 0.0;
    final ventasDig = double.tryParse(_ventasDigitalController.text) ?? 0.0;
    final gastosEf = double.tryParse(_gastosEfectivoController.text) ?? 0.0;
    final gastosDig = double.tryParse(_gastosDigitalController.text) ?? 0.0;
    final totalRealEf = double.tryParse(_totalRealEfectivoController.text) ?? 0.0;
    final notas = _notasController.text.trim();
    
    if (totalRealEf == 0.0 || fondoInicial == 0.0) {
      mostrarDialogoError(context, 'El Fondo Inicial y el Total Contado son obligatorios.');
      return;
    }
    
    setState(() => _estaGuardando = true);

    try {
      await FirebaseFirestore.instance.collection('cierres_caja').add({
        'fecha': _fechaSeleccionada,
        'fondo_inicial': fondoInicial,
        'ventas_efectivo': ventasEf,
        'ventas_otros': ventasDig, 
        'gastos_efectivo': gastosEf,
        'gastos_digital': gastosDig,
        'total_real_contado': totalRealEf,
        'total_calculado_caja': _totalCalculadoEfectivo, 
        'diferencia': _diferencia,
        'notas': notas,
      });

      // Limpieza
      _fondoInicialController.clear();
      _ventasEfectivoController.clear();
      _ventasDigitalController.clear();
      _gastosEfectivoController.clear();
      _gastosDigitalController.clear();
      _totalRealEfectivoController.clear();
      _notasController.clear();
      
      setState(() {
        _totalCalculadoEfectivo = 0.0;
        _diferencia = 0.0;
        _fechaSeleccionada = DateTime.now();
      });
      
      if (mounted) mostrarDialogoExito(context, '¡Cierre guardado correctamente!');

    } catch (e) {
      mostrarDialogoError(context, 'Error al guardar: $e');
    }
    setState(() => _estaGuardando = false);
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores del tema actual para ser consistentes
    final colorPrimario = Theme.of(context).colorScheme.primary;
    final colorSecundario = Theme.of(context).colorScheme.secondary;
    
    return Scaffold(
      // El fondo ya lo pone el TemaApp (crema), no hace falta repetirlo
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // --- HEADER DE FECHA ---
            InkWell(
              onTap: _seleccionarFecha,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  // Borde muy sutil usando el color primario (gris/coral) con baja opacidad
                  border: Border.all(color: colorPrimario.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha del Cierre', 
                          style: Theme.of(context).textTheme.bodySmall
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM', 'es').format(_fechaSeleccionada).toUpperCase(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colorPrimario, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.calendar_month, color: colorPrimario),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // --- SECCIÓN 1: ENTRADAS DE DINERO ---
            Text('Registro de Movimientos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Usamos un Container blanco porque los inputs del tema ya son blancos, 
            // así creamos un bloque limpio.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent, // Dejamos que se vea el fondo crema
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InputCampo(_fondoInicialController, 'Fondo Inicial', Icons.savings_outlined, 'Base en caja', esImportante: true),
                  const SizedBox(height: 16),
                  
                  // Agrupamos Ventas
                  _InputCampo(_ventasEfectivoController, 'Ventas Efectivo', Icons.payments_outlined, 'Billetes recibidos'),
                  const SizedBox(height: 8),
                  _InputCampo(_ventasDigitalController, 'Ventas Digitales', Icons.qr_code, 'Nequi, Daviplata', colorIcono: colorSecundario),
                  
                  const Divider(height: 32),
                  
                  // Agrupamos Gastos
                  _InputCampo(_gastosEfectivoController, 'Gastos Efectivo', Icons.money_off_outlined, 'Salidas físicas'),
                  const SizedBox(height: 8),
                  _InputCampo(_gastosDigitalController, 'Gastos Digitales', Icons.credit_card_off_outlined, 'Transferencias', colorIcono: colorSecundario),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- SECCIÓN 2: EL CUADRE (TARJETA DESTACADA) ---
            // Usamos el color primario del tema para destacar esta sección
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorPrimario, // El Gris/Coral vibrante del tema
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: colorPrimario.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'TOTAL EFECTIVO REAL', 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9), 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2
                    )
                  ),
                  const SizedBox(height: 16),
                  
                  // Input gigante para el total
                  TextField(
                    controller: _totalRealEfectivoController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '\$ 0',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1), // Transparente sobre el fondo oscuro
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), 
                        borderSide: BorderSide.none
                      ),
                      // Quitamos el estilo por defecto del tema para este input específico
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (_) => _calcularDiferencia(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Resultados del cálculo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, // Tarjeta blanca dentro del fondo oscuro
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Column(
                      children: [
                        _FilaResultado(context, 'Sistema calculó:', _totalCalculadoEfectivo, colorPrimario),
                        const Divider(),
                        _FilaResultado(
                          context, 
                          'Diferencia:', 
                          _diferencia, 
                          // Usamos colores semánticos (Verde/Rojo) solo para el resultado
                          _diferencia >= 0 ? Colors.green[700]! : Colors.red[700]!, 
                          esGrande: true
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notas
            TextField(
              controller: _notasController,
              decoration: InputDecoration(
                labelText: 'Notas adicionales',
                prefixIcon: Icon(Icons.note_alt_outlined, color: colorPrimario),
                hintText: 'Ej: Faltaron 200 pesos por...',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Botón de Guardar (Automáticamente toma el estilo del tema)
            _estaGuardando
              ? Center(child: CircularProgressIndicator(color: colorPrimario))
              : FilledButton.icon(
                  onPressed: _guardarCierre,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('GUARDAR CIERRE'),
                ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Respetando diseño) ---
  
  Widget _InputCampo(TextEditingController controller, String label, IconData icon, String hint, {bool esImportante = false, Color? colorIcono}) {
    // Si no pasan color, usamos el primario del tema
    final colorFinal = colorIcono ?? Theme.of(context).colorScheme.primary;
    
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => _calcularDiferencia(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: esImportante ? Theme.of(context).colorScheme.secondary : colorFinal),
        // El resto del estilo (fondo blanco, borde redondeado) lo toma del ThemeApp automáticamente
      ),
    );
  }

  Widget _FilaResultado(BuildContext context, String titulo, double valor, Color color, {bool esGrande = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo, 
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: esGrande ? FontWeight.bold : FontWeight.normal
          )
        ),
        Text(
          currencyFormat.format(valor),
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.bold, 
            fontSize: esGrande ? 20 : 16,
            fontFamily: 'Nunito' // Forzamos la fuente del tema por si acaso
          ),
        ),
      ],
    );
  }
}