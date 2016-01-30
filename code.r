# prepare
# data from last ten seasons on data.vti.be
# only selected collaborations between people with functions 11571, 11741, 11933, 11971, 11977, 12009, 12014, 12018, 12019, 12092, 12156
# where production is not a rerun of anything

library(igraph)
library(jsonlite)

#setwd("C:/Users/ruet/Documents/datasets/data-vti-be/")
df = read.delim("edgelist.el", sep="\t", header=F)
df$V1 = as.character(df$V1)
df$V2= as.character(df$V2)
g = graph.edgelist(as.matrix(df), directed = FALSE)
E(g)$weight <- 1 
g.simple = simplify(g, remove.loops=TRUE) # simplify graph by mapping duplicate edges onto each other, sum weight

# remove passanten
g.simple = delete.edges(g.simple, which(E(g.simple)$weight < 2))
g.simple = delete.vertices(g.simple, which(degree(g.simple) < 2))

# read in persontable
persontable = read.delim("person.table", sep="\t", header=F)
persontable$V1 = as.character(persontable$V1)

# how many actors in this sample?
vcount(g.simple)

# make plot, may take a while...
png("report/full_graph.png", width=5000, height=2500, res=200)
plot(g.simple,
  layout = layout.fruchterman.reingold,
  vertex.label = NA,
  vertex.size = 1.5
)
dev.off()

# how many actors play how often together
png("report/samenwerkingsfrequentiedistributie.png", width=1000, height=600, res=100)
hist(E(g.simple)$weight, breaks=seq(1, max(E(g.simple)$weight), 1), freq=FALSE)
dev.off()

# get subgraphs
V(g.simple)$cluster <- clusters(g.simple)$membership

# biggest group of connected actors make up 72% of whole community
sort(clusters(g.simple)$csize, decreasing=TRUE)[1] / sum(clusters(g.simple)$csize)

# who is in the sizeable seperate subgraphs?
# let's look at unconnected groups of 5 people and more
tenplusgroups = c(1:length(clusters(g.simple)$csize))[clusters(g.simple)$csize < 100 & clusters(g.simple)$csize >= 10]
for (i in tenplusgroups){
  print(i)
  for (j in (V(g.simple)[V(g.simple)$cluster == i])$name) {
    print(as.character(persontable[persontable$V1 == j, ]$V2))
  }
}

# Now select only the biggest connected cluster
g.simple.trim = induced.subgraph(g.simple, V(g.simple)[V(g.simple)$cluster == which.max(clusters(g.simple)$csize)])
vcount(g.simple.trim)

# how many actors play how often together
png("report/samenwerkingsfrequentiedistributie_mainstream.png", width=1000, 600, res=100)
hist(E(g.simple.trim)$weight, breaks=seq(min(E(g.simple.trim)$weight), max(E(g.simple.trim)$weight), 1), freq=FALSE)
dev.off()

# let us see if there are any communities in this
fgc = fastgreedy.community(g.simple.trim)

# plot
V(g.simple.trim)$color <- rainbow(max(fgc$membership))[fgc$membership]
png("report/biggest_cluster_graph_FGCcoloring.png", width=5000, height=3000, res=300)
plot(g.simple.trim,
  layout = layout.fruchterman.reingold,
  vertex.label = NA,
  vertex.size = 2.5
)
dev.off()

# can we interpret the clusters by looking at who is in them?
bet = betweenness(g.simple.trim)
communities = c(1:max(fgc$membership))
for (i in communities){
  print(i)
  for (j in fgc$name[fgc$membership == i]) {
    name = as.character(persontable[persontable$V1 == j, ]$V2)
    print(name)
  }
}

# let's add some network properties of the nodes
metrics <- data.frame(
  deg = degree(g.simple.trim), # number of adjacent edges
  bet = betweenness(g.simple.trim), # number of shortest paths through vertex
  clo = closeness(g.simple.trim), # how many steps is required to access every other vertex
  eig = evcent(g.simple.trim)$vector, # the eigenvector centralities of positions (most important vertices)
  tra = transitivity(g.simple.trim, type=c("local")) # the probability that the adjacent vertices of a vertex are connected
)

# table of nodes
fgc.simple = fastgreedy.community(g.simple)
## id, label, value (centrality), group
nodes = persontable[persontable$V1 %in% V(g.simple)$name, ]
colnames(nodes) = c("id", "label")
nodes$title = nodes$label
values = evcent(g.simple)$vector[nodes$id]
values.norm = ((values - min(values)) / (max(values) - min(values)) * 10) + 10
nodes$value = values.norm
names(fgc.simple$membership) <- fgc.simple$names
nodes$group = fgc.simple$membership[nodes$id]
nodes$id = as.numeric(nodes$id)
write(jsonlite::toJSON(nodes), "report/nodes.json")

# table of edges
## from, to, value (weight)
edges = get.edgelist(g.simple)
colnames(edges) <- c("from", "to")
edges = as.data.frame(edges)
edges$value <- as.vector(E(g.simple)$weight)
edges$from = as.numeric(as.vector(edges$from))
edges$to = as.numeric(as.vector(edges$to))
write(jsonlite::toJSON(edges), "report/edges.json")

