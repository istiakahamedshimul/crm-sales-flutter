import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_crm_sales/models/monthly_collection.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';

class CustomerPaymentsScreen extends StatefulWidget {
  const CustomerPaymentsScreen({super.key});
  @override State<CustomerPaymentsScreen> createState()=>_CustomerPaymentsScreenState();
}
class _CustomerPaymentsScreenState extends State<CustomerPaymentsScreen>{
  late Future<List<MonthlyCollection>> rows=apiClient.getMyMonthlyCollections();
  Future<void> reload()async{setState(()=>rows=apiClient.getMyMonthlyCollections());await rows;}
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:reload,child:FutureBuilder<List<MonthlyCollection>>(
    future:rows,builder:(context,snapshot){
      if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError)return ListView(children:[Padding(padding:const EdgeInsets.all(24),child:Text('Could not load monthly collections.\n${snapshot.error}'))]);
      final items=snapshot.data??const <MonthlyCollection>[];
      if(items.isEmpty)return ListView(children:const [SalesCard(child:Padding(padding:EdgeInsets.all(24),child:Center(child:Text('No monthly collection has been recorded by the CA department.'))))]);
      return ListView.separated(padding:const EdgeInsets.all(12),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(context,index){final row=items[index];return SalesCard(child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:6),leading:const CircleAvatar(child:Icon(Icons.calendar_month_rounded)),title:Text(DateFormat('MMMM yyyy').format(row.month),style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(row.remarks?.trim().isNotEmpty==true?row.remarks!:'Recorded by CA department'),trailing:Text(money(row.amount),style:const TextStyle(fontWeight:FontWeight.w900))));});
    }
  ));
}
