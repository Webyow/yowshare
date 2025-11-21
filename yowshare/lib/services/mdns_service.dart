import 'package:multicast_dns/multicast_dns.dart';
import '../models/device.dart';

class MdnsService {
  final MDnsClient _mdns = MDnsClient();

  Future<void> start() async {
    await _mdns.start();
  }

  Future<void> stop() async {
    _mdns.stop();
  }

  // Broadcast service
  String get serviceName => "_yowshare._tcp.local";

  // Scan for receivers
  Stream<Device> discoverDevices() async* {
    await _mdns.start();

    await for (final PtrResourceRecord ptr
        in _mdns.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(serviceName))) {
      
      await for (final SrvResourceRecord srv
          in _mdns.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
        
        await for (final IPAddressResourceRecord ip
            in _mdns.lookup<IPAddressResourceRecord>(
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
