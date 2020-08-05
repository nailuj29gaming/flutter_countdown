import 'package:countdown/database/moor_db.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ChangeEventScreen extends StatefulWidget {
  DateTime initialDate;
  Countdown countdown;

  ChangeEventScreen({DateTime initialDate, Countdown countdown}) {
    Countdown _countdown;
    DateTime _initialDate;
    if (initialDate != null && countdown != null) {
      throw Exception(
          "Cannot pass both countdown and initialDate to constructor");
    }
    if (countdown != null) {
      _initialDate = countdown.date;
      _countdown = countdown;
    } else if (initialDate != null) {
      // ignore: missing_required_param
      _countdown = null;
      _initialDate = initialDate;
    }
    this.countdown = _countdown;
    this.initialDate = _initialDate;
  }

  @override
  State<StatefulWidget> createState() =>
      _ChangeEventScreenState(dateSet: initialDate, countdown: countdown);
}

class _ChangeEventScreenState extends State<ChangeEventScreen> {
  DateTime dateSet;
  Countdown countdown;
  CountdownsCompanion companion = CountdownsCompanion();
  TextEditingController controller;

  bool get isNew => countdown == null;

  _ChangeEventScreenState({this.dateSet, this.countdown})
      : controller = TextEditingController() {
    if (countdown != null) {
      controller.text = countdown.name;
    }
    print(isNew);
  }
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    return Scaffold(
      appBar: AppBar(
          title: Text("Change Event"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          )),
      body: Container(
        margin: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              DateTimeField(
                initialValue: isNew ? null : countdown.date,
                format: DateFormat.yMMMd(),
                onShowPicker: (context, currentValue) async {
                  final result = await setDate();
                  if (isNew) {
                    companion = CountdownsCompanion.insert(
                        name: companion.name.value, date: result);
                  } else {
                    countdown = Countdown(
                        date: result, name: countdown.name, id: countdown.id);
                  }
                  return result;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Date',
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
                controller: controller,
              ),
              Expanded(
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      RaisedButton(
                        child: Text("Save"),
                        onPressed: () async {
                          if (controller.text == null ||
                              controller.text.isEmpty) {
                            // await Fluttertoast.showToast(
                            //     msg: "You must enter a name",
                            //     toastLength: Toast.LENGTH_SHORT,
                            //     gravity: ToastGravity.BOTTOM,
                            //     timeInSecForIosWeb: 1,
                            //     backgroundColor: Color(0xEEFFFFFF),
                            //     textColor: Colors.black);
                            await EyroToast.showToast(
                                text: "You must enter a name",
                                duration: ToastDuration.short);
                            print("Cannot submit");
                            return;
                          }
                          if (isNew) {
                            companion = CountdownsCompanion.insert(
                                date: dateSet, name: controller.text);
                            database.insertCountdown(companion);
                          } else {
                            countdown = Countdown(
                                id: countdown.id,
                                date: dateSet,
                                name: controller.text);
                            database.updateCountdown(countdown);
                          }

                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text("Cancel"),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime> _getNewDate(DateTime currentDate) async {
    DateTime _date = await showDatePicker(
        context: context,
        initialDate: currentDate,
        firstDate: currentDate.subtract(Duration(days: 365)),
        lastDate: currentDate.add(Duration(days: 365 * 5)));
    if (_date == null) {
      return currentDate;
    }
    return _date;
  }

  setDate() async {
    DateTime _date = await _getNewDate(dateSet);
    setState(() {
      dateSet = _date;
    });
    return _date;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
