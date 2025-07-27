from pox.core import core
from pox.lib.util import dpidToStr
from pox.lib.addresses import IPAddr
import pox.lib.packet as pkt
from pox.lib.revent import EventMixin
import pox.openflow.libopenflow_01 as of
import json

IPV4 = 0x0800

log = core.getLogger()
policy_file = "firewall_policies.json"


def read_ip_address(ip):
    return IPAddr(ip)


def read_port(port):
    return int(port)


def read_protocol(protocol):
    if protocol.upper() == "UDP":
        return pkt.ipv4.UDP_PROTOCOL
    elif protocol.upper() == "TCP":
        return pkt.ipv4.TCP_PROTOCOL
    return None


class Firewall(EventMixin):
    def __init__(self):
        self.listenTo(core.openflow)
        self.add_rules()
        log.debug("Enabling Firewall Module")

    def add_rules(self):
        log.debug("Adding firewall policies: %s", policy_file)
        with open(policy_file, 'r') as f:
            try:
                self.data = json.load(f)
            except json.JSONDecodeError as e:
                log.error("Error decoding JSON policies file: %s", e)

    def _handle_ConnectionUp(self, event):
        selected = self.data.get("selected_switch")
        if selected is not None and event.dpid != selected:
            log.debug("No es el switch seleccionado: %s",
                      dpidToStr(event.dpid))
            return
        for rule in self.data.get("rules"):
            self.add_rule(rule, event)
        log.debug("Firewall rules installed on %s", dpidToStr(event.dpid))

    def add_rule(self, rule_data, event):
        log.debug("Adding rule: %s", rule_data)
        rule = of.ofp_flow_mod()
        rule.match.dl_type = IPV4

        if "src_ip" in rule_data:
            rule.match.nw_src = read_ip_address(rule_data.get("src_ip"))

        if "dst_ip" in rule_data:
            rule.match.nw_dst = read_ip_address(rule_data.get("dst_ip"))

        if "src_port" in rule_data:
            rule.match.tp_src = read_port(rule_data.get("src_port"))

        if "dst_port" in rule_data:
            rule.match.tp_dst = read_port(rule_data.get("dst_port"))

        if "protocol" in rule_data:
            rule.match.nw_proto = read_protocol(rule_data["protocol"])
            event.connection.send(rule)
        else:
            for proto in (pkt.ipv4.TCP_PROTOCOL, pkt.ipv4.UDP_PROTOCOL):
                rule.match.nw_proto = proto
                event.connection.send(rule)

        return rule


def launch():
    log.info("Launching Firewall\n")
    core.registerNew(Firewall)
