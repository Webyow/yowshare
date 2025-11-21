import 'package:multicast_dns/multicast_dns.dart';
import '../models/device.dart';
import '../utils/platform_helper.dart';

class MdnsService {
  MDnsClient? _mdns;

  Future<void> start() async {
    if (!PlatformHelper.supportsMdns()) return;

    _mdns = MDnsClient();
    await _mdns!.start();
  }

  Future<void> stop() async {
    if (!PlatformHelper.supportsMdns()) return;
    _mdns?.stop();
  }

  String get serviceName => "_yowshare._tcp.local";

  Stream<Device> discoverDevices() async* {
    if (!PlatformHelper.supportsMdns()) {
      print("mDNS not supported on this platform");
      return;
    }

    await _mdns!.start();

    await for (final PtrResourceRecord ptr
        in _mdns!.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(serviceName))) {
      
      await for (final SrvResourceRecord srv
          in _mdns!.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
        
        await for (final IPAddressResourceRecord ip
            in _mdns!.lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target))) {

          yield Device(
            name: ptr.domainName.replaceAll("._yowshare._tcp.local", ""),
            ip: ip.address.address,
            port: srv.port,
          );
        }
      }
    }
  }
}
