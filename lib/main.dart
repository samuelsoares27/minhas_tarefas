import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _ListaControler = TextEditingController();
  List _Lista = [];
  Map<String, dynamic> _UltimoRemovido;
  int _UltimoRemovidoPos;

  @override
  void initState() {

    // Reescreve esse método puxando os dados do json e jogando para a lista
    super.initState();

    _readData().then((data){
      setState(() {
        _Lista = json.decode(data);
      });
    });
  }

  void _addLista(){

     if(_ListaControler.text != ""){

       // realiza reenderização
        setState(() {

          // Criou mapa de elementos
          Map<String, dynamic> newLista  = Map();

          // Recebe o string do controlador do campo texto e passa para o title da lista
          newLista["title"] = _ListaControler.text;

          // Limpa e atribui falso para o ícone
          _ListaControler.text = '';
          newLista["ok"] = false;

          // Adiciona na lista
          _Lista.add(newLista);

          // Salvar no Json
          _saveData();
        });
     }
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {

      _Lista.sort((a, b){

        if(a["ok"] && !b["ok"]){
          return 1;
        }else if (!a["ok"] && b["ok"]){
          return -1;
        }else{
          return 0;
        }

        _saveData();
      });

      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _ListaControler,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefas",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: () {
                    _addLista();
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh,
                child:  ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _Lista.length,
                    itemBuilder: buildItem)),
          )
        ],
      ),
    );
  }

  // Função para fazer cada um dos itens da lista
  Widget buildItem(context, index){
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_Lista[index]["title"]),
        value: _Lista[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_Lista[index]["ok"]?
          Icons.check: Icons.error ), ),
        onChanged: (bool value) {
          setState(() {
            _Lista[index]["ok"] = value;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){

        setState(() {


          _UltimoRemovido = Map.from(_Lista[index]);
          _UltimoRemovidoPos = index;
          _Lista.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa\" ${_UltimoRemovido["title"]} \"Removida"),
            action: SnackBarAction(label: "Desfazer",
                onPressed:(){
                  setState(() {
                    _Lista.insert(_UltimoRemovidoPos, _UltimoRemovido);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  // Pegar o Json no app
  Future<File> _getFile() async {
    // Pega o caminho que pode ser salvo o json
    final directory = await getApplicationDocumentsDirectory();

    // Retonar o arquivo data.json pelo caminho
    return File("${directory.path}/data.json");
  }


  // Salvar os dados
  Future<File> _saveData() async {
    //Transforma a Lista em json
    String data = json.encode(_Lista);

    // Abre o arquivo await para esperar por causa do delay
    final file = await _getFile();

    //escreve no arquivo com os dados da lista e retorna
    return file.writeAsString(data);
  }

// Obter os dados
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
