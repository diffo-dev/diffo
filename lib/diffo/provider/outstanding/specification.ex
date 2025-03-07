use Outstand

defoutstanding expected :: Diffo.Provider.Specification, actual :: Any do
  case Outstand.type_of(actual) do
    Diffo.Provider.Specification ->
      if Outstand.nil_outstanding?(expected.name, actual.name) and Outstand.nil_outstanding?(expected.major_version, actual.major_version) do
        nil
      else
        expected
      end
    _ ->
      expected
  end
end
