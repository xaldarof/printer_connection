import 'dart:async';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network/ping_discover_network.dart';

void main() {
  runApp(PrinterApp());
}

class PrinterApp extends StatefulWidget {
  @override
  State<PrinterApp> createState() => _PrinterAppState();
}

class _PrinterAppState extends State<PrinterApp> {
  var devices = <WifiInfoData>[];

  TextEditingController ipController = TextEditingController();
  TextEditingController portController = TextEditingController();
  String messageLog = "";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.connect_without_contact),
          onPressed: () async {
            if (ipController.text.isNotEmpty &&
                portController.text.isNotEmpty) {
              setState(() {
                messageLog = "";
                messageLog = "Connecting...";
              });
              connectToPrinter();
            }
          },
        ),
        body: Column(
          children: [
            Row(
              children: [
                Flexible(
                  flex: 15,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black12),
                    child: TextField(
                      controller: ipController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.only(
                            left: 15, bottom: 10, top: 10, right: 15),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black12),
                    child: TextField(
                      controller: portController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.only(
                            left: 15, bottom: 10, top: 10, right: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Padding(padding: EdgeInsets.only(left: 24)),
                Text(
                  messageLog,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  discoverDevices() async {
    final info = NetworkInfo();
    var wifiIP = await info.getWifiIP();
    var wifiName = await info.getWifiName();
    final String subnet =
        wifiIP.toString().substring(0, wifiIP.toString().lastIndexOf('.'));
    const int port = 80;

    final stream = NetworkAnalyzer.discover2(subnet, port);

    stream.listen((NetworkAddress addr) {
      if (addr.exists) {
        setState(() {
          devices.add(WifiInfoData(ip: addr.ip, name: wifiName.toString()));
        });

        print('Found device: ${addr.ip}');
      }
    });
  }

  void connectToPrinter() async {
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(ipController.text,
        port: int.parse(portController.text));

    if (res == PosPrintResult.success) {
      messageLog += "\nSuccess";
      messageLog = "\nPrinting";
      testReceipt(printer);
      setState(() {
        messageLog += "Sucess connect to ${printer.host}";
      });
      printer.disconnect();
      messageLog += "\nDisconnected !";
    } else {
      setState(() {
        messageLog += "\n${res.msg}";
      });
    }

    print('Print result: ${res.msg}');
  }

  void testReceipt(NetworkPrinter printer) {
    printer.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    printer.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
        styles: const PosStyles(codeTable: 'CP1252'));
    printer.text('Special 2: blåbærgrød',
        styles: PosStyles(codeTable: 'CP1252'));

    printer.text('Bold text', styles: PosStyles(bold: true));
    printer.text('Reverse text', styles: PosStyles(reverse: true));
    printer.text('Underlined text',
        styles: const PosStyles(underline: true), linesAfter: 1);
    printer.text('Align left', styles: PosStyles(align: PosAlign.left));
    printer.text('Align center', styles: PosStyles(align: PosAlign.center));
    printer.text('Align right',
        styles: PosStyles(align: PosAlign.right), linesAfter: 1);

    printer.text('Text size 200%',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    printer.feed(2);
    printer.cut();
  }
}

class WifiInfoData {
  final String name;
  final String ip;

  const WifiInfoData({
    required this.name,
    required this.ip,
  });
}
