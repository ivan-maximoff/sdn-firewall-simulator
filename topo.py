from mininet.topo import Topo
from mininet.link import TCLink


class MyTopo(Topo):
    def __init__(self, num_switches=2):
        Topo.__init__(self)

        if num_switches < 1:
            raise ValueError("Debe haber al menos 1 switch")

        h1 = self.addHost('h1')
        h2 = self.addHost('h2')

        h3 = self.addHost('h3')
        h4 = self.addHost('h4')

        switches = []
        for i in range(num_switches):
            sw = self.addSwitch('s{}'.format(i+1))
            switches.append(sw)

        self.addLink(h1, switches[0], cls=TCLink)
        self.addLink(h2, switches[0], cls=TCLink)

        for i in range(len(switches) - 1):
            self.addLink(switches[i], switches[i + 1])

        self.addLink(h3, switches[-1], cls=TCLink)
        self.addLink(h4, switches[-1], cls=TCLink)


def create(num_switches=2):
    return MyTopo(num_switches=int(num_switches))


topos = {'mytopo': create}