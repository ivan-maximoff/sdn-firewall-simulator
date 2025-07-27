# -*- coding: utf-8 -*-

from pox.core import core
import pox.openflow.libopenflow_01 as of
from pox.lib.addresses import IPAddr
import random
import logging
from pox.lib.packet.ethernet import ethernet

log = core.getLogger()


class NATController(object):
    def __init__(self):
        self.nat_table = {}  # (ip, puerto) => (ip pública, puerto público)
        self.reverse_nat = {}

        core.openflow.addListenerByName("PacketIn", self._handle_PacketIn)

    def _handle_PacketIn(self, event):
        # Si no es un switch de borde, no hacer NAT
        if event.dpid not in [1]:
            self.send_packet(event, event.parsed, of.OFPP_FLOOD)
            return

        packet = event.parsed
        if not packet:
            return

        ip_packet = packet.find('ipv4')
        l4_packet = packet.find('tcp') or packet.find('udp')
        if not ip_packet or not l4_packet:
            return

        _ = event.port
        src_ip = ip_packet.srcip
        dst_ip = ip_packet.dstip
        src_port = l4_packet.srcport
        dst_port = l4_packet.dstport

        # SNAT solo si sale de una subred conocida
        if (src_ip in ["10.0.0.1", "10.0.0.2"] and
                dst_ip in ["10.0.0.3", "10.0.0.4"]):

            if (src_ip, src_port) not in self.nat_table:
                public_ip = IPAddr("192.168.1.1")  # IP pública del NAT
                public_port = random.randint(10000, 60000)
                while any(pub_port == public_port
                          for (_, pub_port) in self.nat_table.values()):
                    public_port += 1

                self.nat_table[(src_ip, src_port)] = (public_ip, public_port)
                self.reverse_nat[(public_ip, public_port)] = (src_ip, src_port)
                log.info("Creada entrada NAT: (%s:%s) -> (%s:%s)",
                         src_ip, src_port, public_ip, public_port)

            public_ip, public_port = self.nat_table[(src_ip, src_port)]

            ip_packet.srcip = public_ip
            l4_packet.srcport = public_port

            ip_packet.payload = l4_packet
            ip_packet.len = None

            packet.set_payload(ip_packet.pack())
            packet.pack()

            self.send_packet(event, packet, of.OFPP_FLOOD)
            return

        # Dnat
        if (dst_ip, dst_port) in self.reverse_nat:
            private_ip, private_port = self.reverse_nat[(dst_ip, dst_port)]

            ip_packet.dstip = private_ip
            l4_packet.dstport = private_port

            packet.set_payload(ip_packet.pack())
            packet.pack()

        self.send_packet(event, packet, of.OFPP_FLOOD)

    def send_packet(self, event, packet, out_port):
        msg = of.ofp_packet_out()
        msg.data = packet.pack()
        msg.actions.append(of.ofp_action_output(port=out_port))
        msg.in_port = event.port
        event.connection.send(msg)


def launch():
    log.info("Launching NAT controller with subnet-aware NAT")
    core.registerNew(NATController)
