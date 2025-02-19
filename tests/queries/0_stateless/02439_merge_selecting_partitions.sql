
drop table if exists rmt;

create table rmt (n int, m int) engine=ReplicatedMergeTree('/test/02439/{shard}/{database}', '{replica}') partition by n order by n;
insert into rmt select number, number from numbers(50);
insert into rmt values (1, 2);
insert into rmt values (1, 3);
insert into rmt values (1, 4);
insert into rmt values (1, 5);
insert into rmt values (1, 6);
insert into rmt values (1, 7);
insert into rmt values (1, 8);
insert into rmt values (1, 9);
-- there's nothing to merge in all partitions but '1'

optimize table rmt partition tuple(123);

set optimize_throw_if_noop=1;
optimize table rmt partition tuple(123); -- { serverError CANNOT_ASSIGN_OPTIMIZE }

select sleepEachRow(3) as higher_probability_of_reproducing_the_issue format Null;
system flush logs;

-- it should not list unneeded partitions where we cannot merge anything
select distinct path from system.zookeeper_log where path like '/test/02439/s1/' || currentDatabase() || '/block_numbers/%'
    and op_num in ('List', 'SimpleList', 'FilteredList') and path not like '%/block_numbers/1';

drop table rmt;
