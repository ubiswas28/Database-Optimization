# Database-Optimization
## Performance tuning begins with understanding execution plan and finding & fixing expensive operators one by one in below flow:

First Lazy spool: Lazy spool is most expensive operator among all, which happens because of duplicate aggregation. We can remove duplicate aggregation by temporary tables, cte, etc.

Second Hash match: which is always because of unsorted data. Which means either missing index or indexes are not properly utilized, which can be because of : 
1. function use in join or where condition
2. First column of existing index is not part of where clause or join
We can address this by adding new index, fixing query to utilize existing index or altering index to new filter configurations.


Keylookup: Keylookup just indicate, that index is missing some data. We can easily resolve it by adding missing column to index key or include part. But there is a catch as, we don't have privilege to alter index all the time. So, some times, we cannot avoid keylookup.

Index Suggestion:
Index key columns are the one which are part of where clause or joins.
Index include columns are the one which are part of only selection.

Partition Elimination: we check if partition are getting eliminated in query or not. As sometimes even tables have partitions still query go for scan instead partition elimination.

A lot of times, I have seen, developer use different datatype in storedprocedure parameters which don't match to actual column. And end up in no partition elimination.

Two reasons why query is not eliminating partition:
1. Data type mismatch or function used on where clause or type casting
2. Partition key column is not part of where clause

BAD Views: Views sometimes becomes bad when developer don't alter them instead they join same table to view which is already part of view to get some extra data. Instead they should write new view or alter existing view to get extra columns

Minimizing sub queries: We can minimize sub queries, if subquries belong to same table to get different column using cross apply or outer apply.
Example we have to get most recent orderdate, order amount, order shipped date, etc for each customer. So instead of writing different sub query for each column, we can use cross apply or outer apply to get data in single query.
