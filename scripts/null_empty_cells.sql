-- script for setting all empty cells in all text-type columns to NULL

do $$
declare
	col text;
begin
	for col in
		select column_name
		from information_schema.columns
		where table_schema = 'stressor_responses'
			and table_name = 'stressor_responses'
			and data_type = 'text'
	loop
		execute format(
			'update stressor_responses.stressor_responses set %I = NULL where trim(%I) = ''''',
			col, col
		);
	end loop;
end;
$$;
