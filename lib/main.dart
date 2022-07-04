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
  String errors = "";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.connect_without_contact),
            onPressed: () async {
              if (ipController.text.isNotEmpty) {
                setState(() {
                  errors = "";
                });
                connectToPrinter(ipController.text);
              }
              devices.clear();
              discoverDevices();
            },
          ),
          body: Column(
            children: [
              Container(
                margin: EdgeInsets.all(12),
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
              Row(
                children: [Text(errors)],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(0.0, 1.0),
                            blurRadius: 6.0,
                          ),
                        ],
                      ),
                      height: 100,
                      child: Column(
                        children: [
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                fit: FlexFit.tight,
                                flex: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      devices[index].name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    Text(devices[index].ip),
                                  ],
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const Spacer()
                        ],
                      ),
                    );
                    ;
                  },
                ),
              )
            ],
          )),
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

  void connectToPrinter(String localIp) async {
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(localIp, port: 9100);

    if (res == PosPrintResult.success) {
      testReceipt(printer);
      setState(() {
        errors += "Sucess connect to ${printer.host}";
      });
      printer.disconnect();
    } else {
      setState(() {
        errors += "\n${res.msg}";
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
