# prepare
# data from last ten seasons on data.vti.be, only selected collaborations between people in productions with function "acteur"

library(igraph)
library(jsonlite)

setwd("C:/Users/ruet/Documents/datasets/data-vti-be/")
df = read.delim("edgelist.el", sep="\t", header=F)
df$V1 = as.character(df$V1)
df$V2= as.character(df$V2)
g = graph.edgelist(as.matrix(df), directed = FALSE)
E(g)$weight <- 1 
g.simple = simplify(g, remove.loops=FALSE) # simplify graph by mapping duplicate edges onto each other, sum weight

persontable = read.delim("person.table", sep="\t", header=F)
persontable$V1 = as.character(persontable$V1)

# how many actors in this sample?
vcount(g.simple)

# make plot, may take a while...
png("full_graph.png", width=5000, height=2500, res=200)
plot(g.simple,
  layout = layout.fruchterman.reingold,
  vertex.label = NA,
  vertex.size = 1.5
)
dev.off()

# how many actors play how often together
hist(E(g.simple)$weight, breaks=seq(1, max(E(g.simple)$weight), 1), freq=FALSE)

# get subgraphs
V(g.simple)$cluster <- clusters(g.simple)$membership

# biggest group of connected actors make up 72% of whole community
sort(clusters(g.simple)$csize, decreasing=TRUE)[1] / sum(clusters(g.simple)$csize)

# who is in the sizeable seperate subgraphs?
## cutting off the biggest group, this is the distribution
hist(clusters(g.simple)$csize[c(2:53)], breaks=16)

## let's look at unconnected groups of 10 people and more
tenplusgroups = c(1:53)[clusters(g.simple)$csize < 20 & clusters(g.simple)$csize > 10]
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
hist(E(g.simple.trim)$weight, breaks=seq(min(E(g.simple.trim)$weight), max(E(g.simple.trim)$weight), 1), freq=FALSE)

# let us see if there are any communities in this
fgc = fastgreedy.community(g.simple.trim)

# plot
V(g.simple.trim)$color <- rainbow(max(fgc$membership))[fgc$membership]
png("biggest_cluster_graph_FGCcoloring.png", width=5000, height=3000, res=200)
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
    print(as.character(persontable[persontable$V1 == j, ]$V2))
    print(bet[j])
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
## id, label, value (centrality), group
nodes = persontable[persontable$V1 %in% V(g.simple.trim)$name, ]
colnames(nodes) = c("id", "label")
nodes$title = nodes$label
values = evcent(g.simple.trim)$vector[nodes$id]
values.norm = ((values - min(values)) / (max(values) - min(values)) * 10) + 10
nodes$value = values.norm
names(fgc$membership) <- fgc$names
nodes$group = fgc$membership[nodes$id]
nodes$id = as.numeric(nodes$id)
write(jsonlite::toJSON(nodes), "nodes.json")

# table of edges
## from, to, value (weight)
edges = get.edgelist(g.simple.trim)
colnames(edges) <- c("from", "to")
edges = as.data.frame(edges)
edges$value <- as.vector(E(g.simple.trim)$weight)
edges$from = as.numeric(as.vector(edges$from))
edges$to = as.numeric(as.vector(edges$to))
write(jsonlite::toJSON(edges), "edges.json")
