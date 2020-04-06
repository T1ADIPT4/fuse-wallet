import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_segment/flutter_segment.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:fusecash/generated/i18n.dart';
import 'package:fusecash/models/app_state.dart';
import 'package:fusecash/models/transactions/transaction.dart';
import 'package:fusecash/models/transactions/transfer.dart';
import 'package:fusecash/models/views/contacts.dart';
import 'package:fusecash/screens/cash_home/cash_header.dart';
import 'package:fusecash/screens/send/send_amount.dart';
import 'package:fusecash/screens/send/send_amount_arguments.dart';
import 'package:fusecash/services.dart';
import 'package:fusecash/utils/format.dart';
import 'package:fusecash/utils/phone.dart';
import 'package:fusecash/utils/transaction_row.dart';
import 'package:fusecash/widgets/main_scaffold.dart';
import "package:ethereum_address/ethereum_address.dart";
import 'dart:math' as math;

class ContactsList extends StatefulWidget {
  final List<Contact> contacts;
  ContactsList({this.contacts});

  @override
  _ContactsListState createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  List<Contact> userList = [];
  List<Contact> filteredUsers = [];
  bool showFooter = true;
  bool hasSynced = false;
  TextEditingController searchController = TextEditingController();
  bool isPreloading = false;

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<AppState, ContactsViewModel>(
        distinct: true,
        onInit: (store) {
          Segment.screen(screenName: '/send-to-contact-screen');
        },
        converter: ContactsViewModel.fromStore,
        builder: (_, viewModel) {
          return MainScaffold(
            automaticallyImplyLeading: false,
            title: I18n.of(context).send_to,
            sliverList: _buildPageList(viewModel),
          );
        });
  }

  loadContacts(List<Contact> contacts) async {
    if (this.mounted) {
      setState(() {
        isPreloading = true;
      });
    }
    for (var contact in contacts) {
      userList.add(contact);
    }
    userList.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    filterList();
    searchController.addListener(() {
      filterList();
    });

    if (this.mounted) {
      setState(() {
        isPreloading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadContacts(widget.contacts);
  }

  void _onFocusChange(hasFocus) {
    if (mounted) {
      setState(() {
        showFooter = !hasFocus;
      });
    }
  }

  filterList() {
    List<Contact> users = [];
    users.addAll(userList);
    if (searchController.text.isNotEmpty) {
      users.retainWhere((user) => user.displayName
          .toLowerCase()
          .contains(searchController.text.toLowerCase()));
    }

    if (this.mounted) {
      setState(() {
        filteredUsers = users;
      });
    }
  }

  listHeader(String title) {
    return SliverPersistentHeader(
      pinned: true,
      floating: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 40.0,
        maxHeight: 40.0,
        child: Container(
          color: Color(0xFFF8F8F8),
          padding: EdgeInsets.only(left: 20, top: 7),
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  sendToContact(BuildContext context, Contact user, ContactsViewModel viewModel) async {
    String phoneNumber = formatPhoneNumber(user.phones.first.value, viewModel.countryCode);
    dynamic data = await api.getWalletByPhoneNumber(phoneNumber);
    String accountAddress = data['walletAddress'] ?? null;
    Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => SendAmountScreen(
                pageArgs: SendAmountArguments(
                    erc20Token: viewModel.isProMode ? viewModel.daiToken : null,
                    sendType: viewModel.isProMode
                        ? SendType.ETHEREUM_ADDRESS
                        : accountAddress != null
                            ? SendType.FUSE_ADDRESS
                            : SendType.CONTACT,
                    name: user.displayName,
                    accountAddress: accountAddress,
                    avatar: user.avatar != null && user.avatar.isNotEmpty
                        ? MemoryImage(user.avatar)
                        : new AssetImage('assets/images/anom.png'),
                    phoneNumber: phoneNumber))));
  }

  listBody(context, ContactsViewModel viewModel, List<Contact> group) {
    List<Widget> listItems = List();

    for (Contact user in group) {
      dynamic component = Slidable(
        actionPane: SlidableDrawerActionPane(),
        actionExtentRatio: 0.25,
        child: Container(
          decoration: new BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: const Color(0xFFDCDCDC)))),
          child: ListTile(
            contentPadding:
                EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
            leading: CircleAvatar(
              backgroundColor: Color(0xFFE0E0E0),
              radius: 25,
              backgroundImage: user.avatar != null && user.avatar.isNotEmpty
                  ? MemoryImage(user.avatar)
                  : new AssetImage('assets/images/anom.png'),
            ),
            title: Text(
              user.displayName,
              style: TextStyle(
                  fontSize: 15, color: Theme.of(context).primaryColor),
            ),
            onTap: () {
              sendToContact(context, user, viewModel);
            },
          ),
        ),
      );

      listItems.add(component);
    }
    return SliverList(
      delegate: SliverChildListDelegate(listItems),
    );
  }

  Widget sendToAcccountAddress(
      ContactsViewModel viewModel, String accountAddress) {
    Widget component = Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: Container(
        decoration: new BoxDecoration(
            border: Border(bottom: BorderSide(color: const Color(0xFFDCDCDC)))),
        child: ListTile(
            contentPadding:
                EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
            leading: CircleAvatar(
              backgroundColor: Color(0xFFE0E0E0),
              radius: 25,
              backgroundImage: new AssetImage('assets/images/anom.png'),
            ),
            title: Text(
              formatAddress(accountAddress),
              style: TextStyle(fontSize: 16),
            ),
            trailing: InkWell(
              child: Text(
                I18n.of(context).next_button,
                style: TextStyle(color: Color(0xFF0377FF)),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => SendAmountScreen(
                            pageArgs: SendAmountArguments(
                                erc20Token: viewModel.isProMode
                                    ? viewModel.daiToken
                                    : null,
                                sendType: viewModel.isProMode
                                    ? SendType.ETHEREUM_ADDRESS
                                    : SendType.PASTED_ADDRESS,
                                accountAddress: accountAddress,
                                name: formatAddress(accountAddress),
                                avatar: new AssetImage(
                                    'assets/images/anom.png')))));
              },
            ),
            //subtitle: Text("user.company" ?? ""),
            onTap: () {
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (context) => SendAmountScreen(
                          pageArgs: SendAmountArguments(
                              erc20Token: viewModel.isProMode
                                  ? viewModel.daiToken
                                  : null,
                              sendType: viewModel.isProMode
                                  ? SendType.ETHEREUM_ADDRESS
                                  : SendType.PASTED_ADDRESS,
                              accountAddress: accountAddress,
                              name: formatAddress(accountAddress),
                              avatar:
                                  new AssetImage('assets/images/anom.png')))));
            }),
      ),
    );
    return SliverList(
      delegate: SliverChildListDelegate([component]),
    );
  }

  Widget recentContacts(int numToShow, ContactsViewModel viewModel) {
    List<Widget> listItems = List();
    final sorted =
        new List<Transaction>.from(viewModel.transactions.list.toSet().toList())
            .where((t) => t.type == 'SEND' && t.isConfirmed())
            .toList()
              ..sort((a, b) => a.blockNumber != null && b.blockNumber != null
                  ? b.blockNumber?.compareTo(a.blockNumber)
                  : b.status.compareTo(a.status));

    Map<String, Transaction> uniqueValues = {};
    for (var item in sorted) {
      final Contact contact = getContact(item, viewModel.reverseContacts,
          viewModel.contacts, viewModel.countryCode);
      var a = contact != null
          ? contact.displayName
          : deducePhoneNumber(item, viewModel.reverseContacts,
              businesses: viewModel.businesses);
      uniqueValues[a] = item;
    }

    dynamic uniqueList = uniqueValues.values.toList().length > numToShow
        ? uniqueValues.values.toList().sublist(0, numToShow)
        : uniqueValues.values.toList();
    for (int i = 0; i < uniqueList.length; i++) {
      final Transfer transfer = uniqueList[i];
      final Contact contact = getContact(transfer, viewModel.reverseContacts,
          viewModel.contacts, viewModel.countryCode);
      final String displatName = contact != null
          ? contact.displayName
          : deducePhoneNumber(transfer, viewModel.reverseContacts,
              businesses: viewModel.businesses);
      dynamic image = getContactImage(transfer, contact, viewModel.businesses);
      listItems.add(
        Slidable(
          actionPane: SlidableDrawerActionPane(),
          actionExtentRatio: 0.25,
          // secondaryActions: <Widget>[
          //   IconSlideAction(
          //     iconWidget: Icon(Icons.star),
          //     onTap: () {},
          //   ),
          //   IconSlideAction(
          //     iconWidget: Icon(Icons.more_horiz),
          //     onTap: () {},
          //   ),
          // ],
          child: Container(
            decoration: new BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: const Color(0xFFDCDCDC)))),
            child: ListTile(
              contentPadding:
                  EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE0E0E0),
                radius: 25,
                backgroundImage: image,
              ),
              title: Text(
                displatName,
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                if (contact == null) {
                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) => SendAmountScreen(
                              pageArgs: SendAmountArguments(
                                  sendType: SendType.FUSE_ADDRESS,
                                  accountAddress: transfer.to,
                                  name: displatName,
                                  avatar: new AssetImage(
                                      'assets/images/anom.png')))));
                } else {
                  sendToContact(context, contact, viewModel);
                }
              },
            ),
          ),
        ),
      );
    }

    if (listItems.isNotEmpty) {
      listItems.insert(
          0,
          Container(
              padding: EdgeInsets.only(left: 15, top: 15, bottom: 8),
              child: Text(I18n.of(context).recent,
                  style: TextStyle(
                      color: Color(0xFF979797),
                      fontSize: 12.0,
                      fontWeight: FontWeight.normal))));
    }
    return SliverList(
      delegate: SliverChildListDelegate(listItems),
    );
  }

  List<Widget> _buildPageList(ContactsViewModel viewModel) {
    List<Widget> listItems = List();

    listItems.add(searchPanel());

    if (searchController.text.isEmpty && !viewModel.isProMode) {
      listItems.add(recentContacts(3, viewModel));
    } else if (isValidEthereumAddress(searchController.text)) {
      listItems.add(sendToAcccountAddress(viewModel, searchController.text));
    }

    Map<String, List<Contact>> groups = new Map<String, List<Contact>>();
    for (Contact c in filteredUsers) {
      String groupName = c.displayName[0];
      if (!groups.containsKey(groupName)) {
        groups[groupName] = new List<Contact>();
      }
      groups[groupName].add(c);
    }

    List<String> titles = groups.keys.toList()..sort();

    for (String title in titles) {
      List<Contact> group = groups[title];
      listItems.add(listHeader(title));
      listItems.add(listBody(context, viewModel, group));
    }

    return listItems;
  }

  searchPanel() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 80.0,
        maxHeight: 100.0,
        child: Container(
          decoration: new BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border:
                  Border(bottom: BorderSide(color: const Color(0xFFDCDCDC)))),
          padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: FocusScope(
                    onFocusChange: (showFooter) => _onFocusChange(showFooter),
                    child: TextFormField(
                      controller: searchController,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(0.0),
                        border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFFE0E0E0), width: 3)),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: const Color(0xFF292929)),
                        ),
                        suffixIcon: Icon(
                          Icons.search,
                          color: Color(0xFFACACAC),
                        ),
                        labelText: I18n.of(context).search,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                child: new FloatingActionButton(
                    heroTag: 'cash_scanner',
                    backgroundColor: const Color(0xFF292929),
                    elevation: 0,
                    child: Image.asset(
                      'assets/images/scan.png',
                      width: 25.0,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    onPressed: () {
                      scanFuseAddress(context);
                    }),
                width: 50.0,
                height: 50.0,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    @required this.minHeight,
    @required this.maxHeight,
    @required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;
  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => math.max(maxHeight, minHeight);
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}