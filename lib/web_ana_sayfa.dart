import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'web_ana_sayfa_desktop.dart' as desktop;
import 'main.dart' show AyarlarSayfasi, BildirimlerSayfasi, YonetimPaneli, YamukKartClipper;

class WebAnaSayfa extends StatelessWidget {
  const WebAnaSayfa({super.key, required this.onGiris, required this.onCikis, required this.onIsIlanlari, required this.onIsIlaniVer, required this.onIkinciEl, required this.onIkinciElIlanVer, required this.onKendiIlanlarim, required this.onIsDetay, required this.onIkinciElDetay});
  final VoidCallback onGiris, onCikis, onIsIlanlari, onIsIlaniVer, onIkinciEl, onIkinciElIlanVer, onKendiIlanlarim;
  final void Function(String id, Map<String,dynamic> data) onIsDetay, onIkinciElDetay;
  bool get _pwa => Uri.base.queryParameters['pwa'] == '1';

  @override
  Widget build(BuildContext context) {
    if (!_pwa) {
      return desktop.WebAnaSayfa(onGiris:onGiris,onCikis:onCikis,onIsIlanlari:onIsIlanlari,onIsIlaniVer:onIsIlaniVer,onIkinciEl:onIkinciEl,onIkinciElIlanVer:onIkinciElIlanVer,onKendiIlanlarim:onKendiIlanlarim,onIsDetay:onIsDetay,onIkinciElDetay:onIkinciElDetay);
    }
    final user = FirebaseAuth.instance.currentUser;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: _pwaBody(context, user),
    );
  }

  Widget _pwaBody(BuildContext context, User? user) {
    if (user == null) {
      return Scaffold(backgroundColor:const Color(0xFFF6F9FD), appBar:AppBar(centerTitle:true,title:const Text('Gözat360')), body:Center(child:Padding(padding:const EdgeInsets.all(24), child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[ClipRRect(borderRadius:BorderRadius.circular(18),child:Image.asset('file_00000000e26c81f58631d89abd23397f.png',fit:BoxFit.contain)),const SizedBox(height:24),SizedBox(width:double.infinity,height:58,child:FilledButton.icon(onPressed:onGiris,icon:const Icon(Icons.login),label:const Text('GİRİŞ YAP / KAYIT OL')))]))));
    }
    return Scaffold(
      backgroundColor:const Color(0xFFF6F9FD),
      appBar:AppBar(backgroundColor:const Color(0xFFF6F9FD),surfaceTintColor:const Color(0xFFF6F9FD),centerTitle:true,title:const Text('Gözat360',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),actions:[IconButton(icon:const Icon(Icons.notifications,size:28),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const BildirimlerSayfasi())))]),
      body:ListView(physics:const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()),padding:const EdgeInsets.fromLTRB(14,8,14,110),children:[
        const SizedBox(height:8),
        const Center(child:Text('Gözat360',style:TextStyle(fontSize:30,fontWeight:FontWeight.bold))),
        const SizedBox(height:4),
        ClipRRect(borderRadius:BorderRadius.circular(18),child:Image.asset('file_00000000e26c81f58631d89abd23397f.png',width:double.infinity,fit:BoxFit.contain)),
        const SizedBox(height:10),
        Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[const Text('Giriş yapıldı',style:TextStyle(fontSize:16,fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(user.email??'',style:const TextStyle(fontSize:14))]))),
        const SizedBox(height:8),
        _AnaKart(renk1:const Color(0xFF1194FF),renk2:const Color(0xFF087CF0),ikon:Icons.search,baslik:'İŞ İLANLARI',alt:'Sana uygun iş fırsatlarını keşfet',onTap:onIsIlanlari),
        const SizedBox(height:12),
        _AnaKart(renk1:const Color(0xFF38A9FF),renk2:const Color(0xFF1688F5),ikon:Icons.edit_note,baslik:'İŞ İLANI VER',alt:'İş fırsatını herkese duyur',onTap:onIsIlaniVer),
        const SizedBox(height:12),
        _AnaKart(renk1:const Color(0xFF2DD56F),renk2:const Color(0xFF12AD50),ikon:Icons.shopping_cart_outlined,baslik:'İKİNCİ EL',alt:'Aradığın ikinci el ürünü bul',onTap:onIkinciEl),
        const SizedBox(height:12),
        _AnaKart(renk1:const Color(0xFF43DB76),renk2:const Color(0xFF20BA58),ikon:Icons.sell_outlined,baslik:'İKİNCİ EL İLANI VER',alt:'Ürününü kolayca ilanla',onTap:onIkinciElIlanVer),
        const SizedBox(height:14),
        _AltKart(ikon:Icons.list_alt,baslik:'KENDİ İLANLARIM',alt:'Tüm ilanlarını görüntüle ve yönet',onTap:onKendiIlanlarim),
        const SizedBox(height:12),
        _AltKart(ikon:Icons.settings,baslik:'AYARLAR',alt:'Uygulama tercihlerini düzenle',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AyarlarSayfasi()))),
        const SizedBox(height:12),
        FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(future:FirebaseFirestore.instance.collection('admins').doc(user.uid).get(),builder:(context,snapshot){final admin=snapshot.data?.exists==true&&snapshot.data?.data()?['role']=='admin';if(!admin)return const SizedBox.shrink();return Column(children:[_AltKart(ikon:Icons.admin_panel_settings,baslik:'YÖNETİM PANELİ',alt:'Sistem yönetimi ve istatistikler',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const YonetimPaneli()))),const SizedBox(height:12)]);}),
        _AltKart(ikon:Icons.logout,baslik:'ÇIKIŞ YAP',alt:'Güvenli şekilde oturumu kapat',onTap:onCikis,iconColor:Colors.red),
      ]),
    );
  }
}

class _AnaKart extends StatelessWidget {
  const _AnaKart({required this.renk1,required this.renk2,required this.ikon,required this.baslik,required this.alt,required this.onTap});
  final Color renk1,renk2; final IconData ikon; final String baslik,alt; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(borderRadius:BorderRadius.circular(22),onTap:onTap,child:ClipPath(clipper:YamukKartClipper(),child:Container(height:88,decoration:BoxDecoration(gradient:LinearGradient(colors:[renk1,renk2]),borderRadius:BorderRadius.circular(22),boxShadow:const[BoxShadow(color:Colors.black12,blurRadius:8,offset:Offset(0,4))]),child:Padding(padding:const EdgeInsets.symmetric(horizontal:18,vertical:10),child:Row(children:[Container(width:58,height:58,decoration:BoxDecoration(color:Colors.white.withOpacity(.15),shape:BoxShape.circle),child:Icon(ikon,color:Colors.white,size:34)),const SizedBox(width:16),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(baslik,style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(alt,style:const TextStyle(color:Colors.white,fontSize:14))])),const Icon(Icons.chevron_right,color:Colors.white,size:42)])))));
  }
}

class _AltKart extends StatelessWidget {
  const _AltKart({required this.ikon,required this.baslik,required this.alt,required this.onTap,this.iconColor=const Color(0xFF405A7A)});
  final IconData ikon; final String baslik,alt; final VoidCallback onTap; final Color iconColor;
  @override
  Widget build(BuildContext context) {
    return InkWell(borderRadius:BorderRadius.circular(18),onTap:onTap,child:Container(height:74,padding:const EdgeInsets.symmetric(horizontal:16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),boxShadow:const[BoxShadow(color:Colors.black12,blurRadius:8,offset:Offset(0,3))]),child:Row(children:[Icon(ikon,size:31,color:iconColor),const SizedBox(width:16),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(baslik,style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:Color(0xFF142A4A))),const SizedBox(height:3),Text(alt,style:const TextStyle(fontSize:12,color:Color(0xFF63738A)))])),const Icon(Icons.chevron_right,size:28,color:Color(0xFF63738A))])));
  }
}
