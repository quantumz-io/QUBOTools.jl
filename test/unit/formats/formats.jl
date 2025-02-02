function test_formats()
    @testset "⦷ Formats ⦷" verbose = true begin
        list = []

        for fmt in QUBOTools.formats()
            test_cases = get(TEST_CASES, fmt, nothing)

            if isnothing(test_cases) || isempty(test_cases)
                continue
            else
                push!(list, fmt)
            end
        end

        for fmt in list
            dom = QUBOTools.domain(fmt)
            test_cases = TEST_CASES[fmt]

            @testset "▷ $(fmt)" begin
                for i in test_cases
                    test_data_path = __data_path(fmt, dom, i)
                    temp_data_path = __temp_path(fmt, dom, i)

                    # if QUBOTools.supports_read(typeof(fmt))
                    test_model = QUBOTools.read_model(test_data_path, fmt)

                    @test test_model isa QUBOTools.Model

                    #     if QUBOTools.supports_write(typeof(fmt))

                    QUBOTools.write_model(temp_data_path, test_model, fmt)

                    temp_model = QUBOTools.read_model(temp_data_path, fmt)

                    @test temp_model isa QUBOTools.Model
                end
            end
        end
    end
end