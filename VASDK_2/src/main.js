window.addEventListener('vaReportComponents.loaded', () => {
    const ddc = vaReportComponents.registerDataDrivenContent({
        authenticationType: "credentials",
        url: "http://va85.gel.sas.com",
        reportUri: "/reports/reports/256c5cec-747a-4e15-8233-45ebcf489a18",
        objectName: "ve71"
    }, displayData);
    function displayData(message) {
        $("#ddc").empty();
        if (message && message.rowCount >= 0) {
            const brushColumnIndex = message.columns.findIndex((column) => column.usage === 'brush');
            $("<table />", { id: "ddcTable", class: "table table-striped table-fixed" }).appendTo("#ddc");
            $("<thead />", { id: "ddcTHead" }).appendTo("#ddcTable");
            $("<tr />", { id: "ddcTableHeader" }).appendTo("#ddcTHead");
            $.each(message.columns, function (id, columnName) {
                if (id != brushColumnIndex) {
                    $("<th />", { text: columnName.label, class: "col-6" }).appendTo("#ddcTableHeader");
                }
            });
            $("<tbody />", { id: "ddcTBody" }).appendTo("#ddcTable");
            $.each(message.data, function (id, row) {
                $("<tr />", { id: "row" + id, value: row[0] }).appendTo("#ddcTBody");
                $.each(row, function (col, value) {
                    if (!isNaN(value)) {
                        value = parseFloat(value).toLocaleString('en', { style: 'currency', currency: 'USD', minimumFractionDigits: 2, maximumFractionDigits: 2 });
                    }
                    if (col != brushColumnIndex){
                        $("<td />", { id: "col" + col, text: value, class: "col-6" }).appendTo("#row" + id);
                    }
                });
            });
            $("#ddcTBody tr").click(function () {
                $("#noSourceIframe").remove();
                $("#manufacturerInfo").attr("src", "https://www.car-logos.org/" + $(this).attr('value'));
                let rowID = $(this).attr("id").substring(3);
                let selections = [{ row: parseInt(rowID) }];
                let resultName = message.resultName;
                ddc.dispatch({ resultName, selections });
            })
        };
    }
}
);
