#
#  Helper recipe to populate the redisio ci attributes
#

ci = node.workorder.rfcCi.ciAttributes

node.set[:redisio][:source_url] = ci['src_url']
node.set[:version] = ci['version']