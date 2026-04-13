import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final salesBox = Hive.box('salesBox');
  final settingsBox = Hive.box('settingsBox');

  String search = "";

  int totalMoney() {
    int total = 0;
    for (var i = 0; i < salesBox.length; i++) {
      var item = salesBox.getAt(i);
      int price = int.tryParse(item['price'].toString()) ?? 0;
      total += price;
    }
    return total;
  }

  
  int calculateBottlePrice(int bottleQty) {
    int bottlePrice = settingsBox.get("bottlePrice", defaultValue: 22000);

    int pack6 = bottleQty ~/ 6; // ຈຳນວນຊຸດ 6
    int remain = bottleQty % 6;

    int total = (pack6 * 130000) + (remain * bottlePrice);
    return total;
  }

 
  void addData() {
    final name = TextEditingController();
    final village = TextEditingController();
    final crateQty = TextEditingController();
    final bottleQty = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text("🍺 ເພີ່ມອໍເດີ້"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: "ຊື່ລູກຄ້າ"),
            ),
            TextField(
              controller: village,
              decoration: InputDecoration(labelText: "ບ້ານ"),
            ),
            SizedBox(height: 10),

            TextField(
              controller: crateQty,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "ລັງ",
                prefixIcon: Icon(Icons.inventory),
              ),
            ),

            TextField(
              controller: bottleQty,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "ແກ້ວ",
                prefixIcon: Icon(Icons.local_drink),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              int crate = int.tryParse(crateQty.text) ?? 0;
              int bottle = int.tryParse(bottleQty.text) ?? 0;

              int cratePrice =
                  settingsBox.get("cratePrice", defaultValue: 260000);

              int total =
                  (crate * cratePrice) + calculateBottlePrice(bottle);

              salesBox.add({
                "name": name.text,
                "village": village.text,
                "crate": crate,
                "bottle": bottle,
                "price": total,
                "paid": false,
              });

              Navigator.pop(context);
              setState(() {});
            },
            child: Text("💾 ບັນທຶກ"),
          )
        ],
      ),
    );
  }


  void togglePaid(int index) {
    var item = salesBox.getAt(index);
    item['paid'] = !item['paid'];
    salesBox.putAt(index, item);
    setState(() {});
  }

 
  void showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("⚠️ ຢືນຢັນ"),
        content: Text("ຕ້ອງການລຶບອໍເດີ້ນີ້ບໍ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ຍົກເລີກ"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              salesBox.deleteAt(index);
              Navigator.pop(context);
              setState(() {});
            },
            child: Text("ລຶບ"),
          ),
        ],
      ),
    );
  }

 
  List getFiltered() {
    return List.generate(salesBox.length, (i) => salesBox.getAt(i))
        .where((item) {
      return item['name']
          .toLowerCase()
          .contains(search.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var list = getFiltered();

    return Scaffold(
      appBar: AppBar(
        title: Text("🍺 Beer Sales"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "ຄົ້ນຫາລູກຄ້າ...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),

         
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [Colors.green, Colors.teal],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ລວມເງິນ",
                    style: TextStyle(color: Colors.white)),
                Text(
                  "${totalMoney()} ກີບ",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

         
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                var item = list[i];
                bool paid = item['paid'];

                return Container(
                  margin:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: paid
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                  ),
                  child: ListTile(
                    onLongPress: () {
                      showDeleteDialog(i);
                    },
                    leading: CircleAvatar(
                      backgroundColor:
                          paid ? Colors.green : Colors.red,
                      child: Icon(
                        paid ? Icons.check : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(item['name']),
                    subtitle: Text(
                        "🍺 ${item['crate']} ລັງ | 🥤 ${item['bottle']} ແກ້ວ\n💰 ${item['price']} ກີບ"),
                    trailing: TextButton(
                      onPressed: () => togglePaid(i),
                      child: Text(
                        paid ? "ຈ່າຍແລ້ວ" : "ຍັງບໍ່ຈ່າຍ",
                        style: TextStyle(
                          color:
                              paid ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),

      floatingActionButton: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton.icon(
          onPressed: addData,
          icon: Icon(Icons.add),
          label: Text(
            "ເພີ່ມອໍເດີ້",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}