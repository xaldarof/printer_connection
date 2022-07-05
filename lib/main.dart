import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
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
  var printSizes = <PaperSize>[PaperSize.mm58, PaperSize.mm80];
  var printSizesTitles = <PrintSize>[
    PrintSize(title: "MM 58", isSelected: false),
    PrintSize(title: "MM 80", isSelected: false)
  ];

  int selectedPaperSize = -1;

  TextEditingController ipController = TextEditingController();
  TextEditingController portController = TextEditingController();
  var messageLog = <String>[];
  var successMessage = "";
  var bruteForce = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.connect_without_contact),
          onPressed: () async {
            var devices = await FlutterUsbPrinter.getUSBDeviceList();
            print("Devices  $devices");

            if (ipController.text.isNotEmpty || bruteForce) {
              setState(() {
                successMessage = "";
              });

              _discoverSubConnections();
              _printLog("");
              _printLog("Discovering devices...");
              _printLog(
                  "[${printSizesTitles[selectedPaperSize].title}]Connecting...");
              _connectToPrinter();
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
                  flex: 2,
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
                Checkbox(
                    value: bruteForce,
                    onChanged: (value) {
                      setState(() {
                        bruteForce = value ?? false;
                      });
                    }),
                const Padding(padding: EdgeInsets.all(12))
              ],
            ),
            Text(successMessage,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16)),
            Flexible(
              flex: 1,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: printSizesTitles.length,
                itemBuilder: (context, index) {
                  var backgroundColor = Color(Colors.white.value);
                  if (index == selectedPaperSize) {
                    backgroundColor = Color(Colors.blue[300]?.value ?? 1);
                  } else {
                    backgroundColor = Color(Colors.white.value);
                  }

                  return Row(
                    children: [
                      GestureDetector(
                        child: Container(
                          width: 128,
                          height: 128,
                          margin: const EdgeInsets.all(12),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.0),
                            color: backgroundColor,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.grey,
                                offset: Offset(0.0, 1.0),
                                blurRadius: 6.0,
                              ),
                            ],
                          ),
                          child: Text(
                            printSizesTitles[index].title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 16),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedPaperSize = index;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            Flexible(
              flex: 8,
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: messageLog.length,
                itemBuilder: (context, index) {
                  return Row(children: [
                    GestureDetector(
                        child: Container(
                      margin: EdgeInsets.all(12),
                      child: Text(
                        messageLog[index],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16),
                      ),
                    ))
                  ]);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _discoverSubConnections() async {
    final String ip = (await NetworkInfo().getWifiIP()).toString();
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    const int port = 80;

    final stream = NetworkAnalyzer.discover2(subnet, port);
    stream.listen((NetworkAddress addr) {
      if (addr.exists) {
        setState(() {
          _printLog("Subnet device ${addr.ip}");
        });
      }
    });
  }

  void _connectToPrinter() async {
    if (bruteForce) {
      for (int i = 0; i < 255; i++) {
        _connect("192.168.0.$i", portController.text);
        _printLog("Try to connect 192.168.0.$i}");
      }
    } else {
      _connect(null, null);
    }
  }

  void _connect(String? ip, String? port) async {
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(printSizes[selectedPaperSize], profile);

    final PosPrintResult res = await printer.connect(ip ?? ipController.text,
        port: int.parse(port ?? portController.text));

    if (res == PosPrintResult.success) {
      _printLog("Success connect to $port");
      _printLog("Printing...");

      _testReceipt(printer);
      setState(() {
        successMessage = "Sucess connect to ${printer.host}";
        _printLog("Sucess connect to ${printer.host}");
      });
      printer.disconnect();
      _printLog("Disconnected !");
    } else {
      _printLog(
          "${res.msg} to ${ip ?? ipController.text}     [${port ?? ipController.text}]");
    }
  }

  void _testReceipt(NetworkPrinter printer) {
    var date = DateTime.now();
    printer.text(
        "Xoldarov Temur check ${date.hour}/${date.minute}/${date.second}",
        styles: const PosStyles(bold: true, align: PosAlign.center));

    printer.feed(2);
    printer.cut();
  }

  _printLog(String message) {
    setState(() {
      if (message.isNotEmpty) {
        messageLog.add(message);
      } else {
        messageLog.clear();
      }
    });
  }
}

class PrintSize {
  String title;
  bool isSelected;

  PrintSize({
    required this.title,
    required this.isSelected,
  });
}
